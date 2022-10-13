//
//  ShareClientItemCell.swift
//  ownCloud
//
//  Created by Matthias Hühne on 16.05.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2019, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit
import ownCloudSDK

open class ShareClientItemCell: ClientItemResolvingCell {
	var iconSize : CGSize = CGSize(width: 40, height: 40)

	// MARK: - Share Item
	open override func titleLabelString(for item: OCItem?) -> NSAttributedString {
		if let shareItemPath = share?.itemLocation.path {
			return NSMutableAttributedString()
					.appendBold(shareItemPath)
		}

		return super.titleLabelString(for: item)
	}

	public var share : OCShare? {
		didSet {
			if let share = share {
				if share.itemType == .folder {
					self.iconView.activeViewProvider = ResourceItemIcon.folder
				} else {
					self.iconView.activeViewProvider = ResourceItemIcon.file
				}

				self.itemResolutionLocation = share.itemLocation

				self.updateLabels(with: item)
			}
		}
	}
}
