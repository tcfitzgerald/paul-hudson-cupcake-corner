//
//  ContentView.swift
//  CupcakeCorner
//
//  Created by tfitzgerald on 9/16/20.
//  Copyright © 2020 Theodore Fitzgerald. All rights reserved.
//

import SwiftUI

struct Order: Codable {
    static let types = ["Vanilla", "Chocolate", "Strawberry", "Rainbow"]
    
    var type = 0
    var quantity = 3
    var extraFrosting = false
    var addSprinkles = false
    var specialRequestEnabled = false
    
    var name: String = ""
    var streetAddress = ""
    var city = ""
    var zip = ""
}


class OrderViewModel: ObservableObject {
    
    @Published var order: Order = Order()
    @Published var showingConfirmation: Bool = false
    @Published var confirmationMessage: String = ""
    
    var isValid: Bool {
        if order.name.isEmpty || order.streetAddress.isEmpty || order.city.isEmpty || order.zip.isEmpty { return false }
        
        return true
    }
    
    func placeOrder() {
        guard let encoded = try? JSONEncoder().encode(order) else {
            print("Failed to encode order")
            return
        }
        
       
        let url = URL(string: "https://reqres.in/api/cupcakes")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encoded
        
        URLSession.shared.dataTask(with: request) { data, response, err in
            guard let data = data, err == nil else { return }
            
            if let decodedOrder = try? JSONDecoder().decode(Order.self, from: data) {
                DispatchQueue.main.async {
                    self.showingConfirmation = true
                    self.confirmationMessage = "Your order for \(decodedOrder.quantity)x \(Order.types[decodedOrder.type].lowercased()) cupcakes is on its way!"
                }

            }
            
        }.resume()

    }
    
}

struct ContentView: View {
    
    @ObservedObject var orderVM = OrderViewModel()

    
    var body: some View {
        NavigationView{
            Form {
                Section {
                    Picker(selection: $orderVM.order.type, label: Text("Select your cake type")) {
                        ForEach(0..<Order.types.count) {
                            Text(Order.types[$0]).tag($0)
                        }
                    }
                    
                    Stepper(value: $orderVM.order.quantity, in: 3...20) {
                        Text("Number of cakes: \(orderVM.order.quantity)")
                    }
                }
                
                Section {
                    
                    Toggle(isOn: $orderVM.order.specialRequestEnabled) {
                        Text("Any special requests?")
                    }
                    
                    if orderVM.order.specialRequestEnabled {
                        Toggle(isOn: $orderVM.order.extraFrosting) {
                            Text("Add extra frosting")
                        }
                        
                        Toggle(isOn: $orderVM.order.addSprinkles) {
                            Text("Add extra sprinkles")
                        }
                    }

                }
                
                Section {
                    TextField("Name", text: $orderVM.order.name)
                    TextField("Street Address", text: $orderVM.order.streetAddress)
                    TextField("City", text: $orderVM.order.city)
                    TextField("Zip", text: $orderVM.order.zip)
                }
                

                Section {
                    Button(action: {
                        orderVM.placeOrder()
                    }) {
                        Text("Place order")
                    }.disabled(!orderVM.isValid)
                }
            }
        .navigationBarTitle(Text("Cupake Corner"))
            .alert(isPresented: $orderVM.showingConfirmation, content: {
                Alert(title: Text("Thank you!"), message: Text(orderVM.confirmationMessage), dismissButton: .default(Text("OK")))
            })
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
