//
//  CategoryTitleView.swift
//  Ulry
//
//  Created by Mattia Righetti on 16/04/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import SwiftUI

struct CategoryTitleView: View {
    var category: Category
    
    var body: some View {
        HStack {
            if let iconName = category.cellContent.icon {
                Image(systemName: iconName)
                    .foregroundColor(Color(uiColor: category.cellContent.backgroundColor))
            } else {
                Circle()
                    .foregroundColor(Color(uiColor: category.cellContent.backgroundColor))
                    .frame(width: 15)
            }

            Text(category.cellContent.title)
        }
    }

    static func getView(for category: Category) -> UIView {
        let view = UIHostingController(rootView: CategoryTitleView(category: category)).view
        view!.backgroundColor = .clear
        return view!
    }
}

struct CategoryTitleView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryTitleView(category: .starred)
    }
}
