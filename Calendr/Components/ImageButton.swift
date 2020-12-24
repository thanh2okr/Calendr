//
//  ImageButton.swift
//  Calendr
//
//  Created by Paker on 24/11/2022.
//

import Cocoa

class ImageButton: CursorButton {

    init(image: NSImage? = nil, cursor: NSCursor? = .pointingHand, glassStyle: Bool = false) {
        super.init(cursor: cursor)
        self.image = image

        if glassStyle {
            isBordered = true
            bezelStyle = .glass
        } else {
            isBordered = false
            bezelStyle = .accessoryBarAction
        }
        showsBorderOnlyWhileMouseInside = true
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
