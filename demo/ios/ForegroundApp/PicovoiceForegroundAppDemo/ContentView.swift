//
//  Copyright 2018-2023 Picovoice Inc.
//  You may not use this file except in compliance with the license. A copy of the license is located in the "LICENSE"
//  file accompanying this source.
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
//  specific language governing permissions and limitations under the License.
//

import SwiftUI
import Picovoice

struct ContentView: View {

    let ACCESS_KEY = "Tw4jothrMMLyRYQ793yD/XF3DeithcbeNVsYlNN0Dc1vY26suWNOkg=="

    let language: String = ProcessInfo.processInfo.environment["LANGUAGE"]!
    let wakeword: String = ProcessInfo.processInfo.environment["WAKEWORD"]!
    let context: String = ProcessInfo.processInfo.environment["CONTEXT"]!

    @State var textTimer: Timer?

    @State var picovoiceManager: PicovoiceManager!
    @State var buttonLabel = "START"
    @State var result: String = ""
    @State var errorMessage: String = ""

    var body: some View {

        VStack {
            Spacer()
            Spacer()
            Text("\(result)")
                .foregroundColor(Color.black)
                .padding()

            Text(errorMessage)
                .padding()
                .background(Color.red)
                .foregroundColor(Color.white)
                .frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width - 50)
                .font(.body)
                .opacity(errorMessage.isEmpty ? 0 : 1)
                .cornerRadius(.infinity)
            Spacer()

            Text("Wake word: \(wakeword)\nContext: \(context)")
                .padding()
                .foregroundColor(Color.black)
                .multilineTextAlignment(.center)

            Button(action: {
                if self.buttonLabel == "START" {
                    self.textTimer?.invalidate()
                    self.result = ""

                    let token = (language == "en") ? "" : "_\(language)"

                    let keywordPath = Bundle.main.url(
                        forResource: "\(wakeword)_ios",
                        withExtension: "ppn",
                        subdirectory: "keywords")!
                    let ppnModelPath = Bundle.main.url(
                        forResource: "porcupine_params\(token)",
                        withExtension: "pv",
                        subdirectory: "models")!

                    let contextPath = Bundle.main.url(
                        forResource: "\(context)_ios",
                        withExtension: "rhn",
                        subdirectory: "contexts")!
                    let rhnModelPath = Bundle.main.url(
                        forResource: "rhino_params\(token)",
                        withExtension: "pv",
                        subdirectory: "models")!

                    do {
                        self.picovoiceManager = PicovoiceManager(
                            accessKey: self.ACCESS_KEY,
                            keywordPath: keywordPath.path,
                            onWakeWordDetection: {
                                result = "Wake Word Detected!\nListening for command..."
                            },
                            contextPath: contextPath.path,
                            onInference: { x in
                                DispatchQueue.main.async {
                                    result = "{\n"
                                    self.result += "    \"isUnderstood\" : \"" + x.isUnderstood.description + "\",\n"
                                    if x.isUnderstood {
                                        self.result += "    \"intent : \"" + x.intent + "\",\n"
                                        if !x.slots.isEmpty {
                                            result += "    \"slots\" : {\n"
                                            for (k, v) in x.slots {
                                                self.result += "        \"" + k + "\" : \"" + v + "\",\n"
                                            }
                                            result += "    }\n"
                                        }
                                    }
                                    result += "}\n"
                                }

                                self.textTimer = Timer.scheduledTimer(withTimeInterval: 1.75, repeats: false) { _ in
                                    if buttonLabel == "STOP" {
                                        result = "Listening for Wake Word.."
                                    }
                                }
                            },
                            porcupineModelPath: ppnModelPath.path,
                            rhinoModelPath: rhnModelPath.path)

                        try self.picovoiceManager.start()

                        self.buttonLabel = "STOP"
                        self.result = "Listening for Wake Word..."
                    } catch let error as PicovoiceInvalidArgumentError {
                        errorMessage = "\(error.localizedDescription)\nEnsure your AccessKey '\(ACCESS_KEY)' is valid"
                    } catch is PicovoiceActivationError {
                        errorMessage = "ACCESS_KEY activation error"
                    } catch is PicovoiceActivationRefusedError {
                        errorMessage = "ACCESS_KEY activation refused"
                    } catch is PicovoiceActivationLimitError {
                        errorMessage = "ACCESS_KEY reached its limit"
                    } catch is PicovoiceActivationThrottledError {
                        errorMessage = "ACCESS_KEY is throttled"
                    } catch {
                        errorMessage = "\(error)"
                    }

                } else {
                    self.picovoiceManager.stop()
                    self.buttonLabel = "START"
                    self.result = ""
                    self.textTimer?.invalidate()
                }
            }) {
                Text("\(buttonLabel)")
                    .padding()
                    .background(errorMessage.isEmpty ? Color.blue : Color.gray)
                    .foregroundColor(Color.white)
                    .font(.largeTitle)
            }.disabled(!errorMessage.isEmpty)
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(Color.white)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
