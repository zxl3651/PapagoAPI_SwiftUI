//
//  ContentView.swift
//  PapagoTranslationAPI_SwiftUI
//
//  Created by 이성현 on 2023/10/18.
//

import SwiftUI
import Alamofire

extension Bundle {
    var Client_ID : String? {
        guard let file = self.path(forResource: "TranslateInfo", ofType: "plist"),
              let resource = NSDictionary(contentsOfFile: file),
              let key = resource["Client_id"] as? String else {
            print("에러 발생")
            return nil
        }
        return key
    }
    var Client_SECRET : String? {
        guard let file = self.path(forResource: "TranslateInfo", ofType: "plist"),
              let resource = NSDictionary(contentsOfFile: file),
              let key = resource["Client_secret"] as? String else {
            print("에러 발생")
            return nil
        }
        return key
    }
}

struct ContentView: View {
    
    @State private var inputText = ""
    @State private var targetLanguage = "en"
    @State private var translatedText : String?
    @State private var isLoading = false
    private var CLIENT_ID = Bundle.main.Client_ID!
    private var CLIENT_SECRET = Bundle.main.Client_SECRET!
    
    
    var body: some View {
        
        NavigationView{
            
            VStack{
                
                TextField("번역할 텍스트 입력", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
                    .padding()
                
                Picker("대상 언어", selection: $targetLanguage, content: {
                    Text("영어").tag("en")
                    Text("스페인어").tag("es")
                    Text("프랑스어").tag("fr")
                }) // Picker
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                Button("번역하기!"){
                    translate()
                }
                .buttonStyle(.borderedProminent)
                
                if isLoading{
                    ProgressView()
                }
                if let translatedText = translatedText {
                    Text("파파고 번역 결과")
                        .fontWeight(.bold)
                        .font(.system(size: 30))
                        .padding(.top, 40)
                    Text("\(translatedText)")
                        .padding()
                }
                
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("파파고 번역 API")
                        .fontWeight(.bold)
                        .font(.system(size: 30))
                        .padding(.top, 40)
                }
            }
        }
    }
    
    func translateText(text: String, targetLanguage: String, completionHandler: @escaping (String?, Error?) -> Void) {
        let apiURL = "https://openapi.naver.com/v1/papago/n2mt"
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
            "X-Naver-Client-Id": CLIENT_ID,
            "X-Naver-Client-Secret": CLIENT_SECRET
        ]
        
        let parameters = "source=ko&target=\(targetLanguage)&text=\(text)"
       
        
        if let url = URL(string: apiURL) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = parameters.data(using: .utf8)
            
            AF.request(request).responseJSON { response in
                switch response.result{
                case .success(let value):
                    print("성공")
                    do {
                        // value 는 Any 타입이기 때문에 Data 타입으로 바로 변환이 되지 않는다!
                        // 따라서 value(Any)를 JSON으로 변경을 먼저 해주고,
                        let dataJSON = try JSONSerialization.data(withJSONObject: value)
                        
                        // JSON Decoder를 사용한다. (Codable)
                        let json = try JSONDecoder().decode(PapagoResModel.self, from: dataJSON)
                        
                        completionHandler(json.message.result.translatedText, nil)
                    } catch {
                        print(error)
                    }
                case .failure(let error):
                    print("실패 : \(error)")
                }
            }
            
            
//          Codable 사용
//            let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                if let error = error {
//                    completionHandler(nil, error)
//                } else if let data = data {
//                    if let json = try? JSONDecoder().decode(PapagoResModel.self, from: data){
//                        completionHandler(json.message.result.translatedText, nil)
//                    }
//                }
//            }
            
            // 기존 방법
//            let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                if let error = error {
//                    completionHandler(nil, error)
//                } else if let data = data {
//                    do {
//                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                           let translatedText = json["message"] as? [String: Any],
//                           let translatedTextString = translatedText["result"] as? [String: Any],
//                           let text = translatedTextString["translatedText"] as? String {
//                            completionHandler(text, nil)
//                        }
//                    } catch {
//                        completionHandler(nil, error)
//                    }
//                }
//            }
            
        }
    }
    
    func translate() {
        isLoading = true
        translatedText = nil
        
        translateText(text: inputText, targetLanguage: targetLanguage) { translation, error in
            DispatchQueue.main.async {
                isLoading = false
                if let translation = translation {
                    translatedText = translation
                } else if let error = error {
                    print("에러: \(error)")
                }
            }
        }
    }
}

// 모든 구조체는 Codable을 준수해야한다!
struct PapagoResModel : Codable { // json 형식을 파일
    let message : Message
}

struct Message : Codable {
    let result: Result
}

struct Result : Codable {
    let engineType: String
    let srcLangType: String
    let tarLangType: String
    let translatedText: String
}

#Preview {
    ContentView()
}
