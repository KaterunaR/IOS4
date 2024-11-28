import SwiftUI
import Foundation

// Model
struct CryptoCurrency: Identifiable, Decodable {
    let id: String
    let symbol: String
    let name: String
    let current_price: Double
    let market_cap: Double
    let total_volume: Double
}

// API
class CryptoAPI {
    private let baseURL = "https://api.coingecko.com/api/v3"
    
    func fetchCryptoData(completion: @escaping ([CryptoCurrency]?, Error?) -> Void) {
        guard let url = URL(string: "\(baseURL)/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&page=1") else {
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            // decode
            do {
                let decoder = JSONDecoder()
                let cryptocurrencies = try decoder.decode([CryptoCurrency].self, from: data)
                completion(cryptocurrencies, nil)
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }
}

// ViewModel
class CryptoViewModel: ObservableObject {
    @Published var cryptocurrencies: [CryptoCurrency] = []
    private var cryptoAPI = CryptoAPI()

    func loadCryptoData() {
        cryptoAPI.fetchCryptoData { [weak self] (data, error) in
            if let error = error {
                print("Error fetching data: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                self?.cryptocurrencies = data ?? []
            }
        }
    }
}

// View
struct ContentView: View {
    @StateObject private var viewModel = CryptoViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.cryptocurrencies) { crypto in
                VStack(alignment: .leading) {
                    Text("\(crypto.name) (\(crypto.symbol.uppercased()))")
                        .font(.headline)
                    
                    Text("Price: \(crypto.current_price, specifier: "%.2f") USD")
                    Text("Market Cap: \(crypto.market_cap, specifier: "%.0f") USD")
                    Text("Total Volume: \(crypto.total_volume, specifier: "%.0f") USD")
                }
            }
            .onAppear {
                viewModel.loadCryptoData()
            }
            .navigationTitle("Cryptocurrencies")
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
