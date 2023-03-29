//
//  ThemeCollection.swift
//  ownCloud
//
//  Created by Felix Schwarz on 10.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

// MARK: - Color Sets
private struct ThemeColorSet {
	var labelColor: UIColor
	var secondaryLabelColor: UIColor

	var iconColor: UIColor	//!< Icons (non-interactive)
	var tintColor: UIColor	//!< User-interactive buttons, accessories

	var backgroundColor: UIColor

	static func from(backgroundColor: UIColor, tintColor: UIColor, for style: UIUserInterfaceStyle) -> ThemeColorSet {
		let preferredtTraitCollection = UITraitCollection(userInterfaceStyle: (style == .light) ? .light : .dark)
		let preferredPrimaryLabelColor = UIColor.label.resolvedColor(with: preferredtTraitCollection)
		let preferredSecondaryLabelColor = UIColor.secondaryLabel.resolvedColor(with: preferredtTraitCollection)

		let alternateTraitCollection = UITraitCollection(userInterfaceStyle: (style == .light) ? .dark : .light)
		let alternatePrimaryLabelColor = UIColor.label.resolvedColor(with: alternateTraitCollection)
		let alternateSecondaryLabelColor = UIColor.secondaryLabel.resolvedColor(with: alternateTraitCollection)

		let labelColor = backgroundColor.preferredContrastColor(from: [preferredPrimaryLabelColor, alternatePrimaryLabelColor]) ?? preferredPrimaryLabelColor
		let secondaryLabelColor = backgroundColor.preferredContrastColor(from: [preferredSecondaryLabelColor, alternateSecondaryLabelColor]) ?? preferredSecondaryLabelColor
		let iconColor = labelColor

		return ThemeColorSet(labelColor: labelColor, secondaryLabelColor: secondaryLabelColor, iconColor: iconColor, tintColor: tintColor, backgroundColor: backgroundColor)
	}

	func disabledSet(for style: UIUserInterfaceStyle) -> ThemeColorSet {
		return ThemeColorSet(labelColor: secondaryLabelColor.greyscale, secondaryLabelColor: secondaryLabelColor.greyscale, iconColor: secondaryLabelColor.greyscale, tintColor: tintColor.greyscale, backgroundColor: backgroundColor.greyscale)
	}

	func highlightedSet(for style: UIUserInterfaceStyle) -> ThemeColorSet {
		var highlightedColorSet = self

		switch style {
			case .light: highlightedColorSet.backgroundColor = highlightedColorSet.backgroundColor.darker(0.10)
			case .dark:  highlightedColorSet.backgroundColor = highlightedColorSet.backgroundColor.lighter(0.15)
			default: break
		}

		return highlightedColorSet
	}
}

private struct ThemeColorStateSet {
	var regular: ThemeColorSet

	var selected: ThemeColorSet
	var highlighted: ThemeColorSet
	var disabled: ThemeColorSet

	static func from(colorSet: ThemeColorSet, for style: UIUserInterfaceStyle) -> ThemeColorStateSet {
		let highlightedSet = colorSet.highlightedSet(for: style)

		return ThemeColorStateSet(regular: colorSet, selected: highlightedSet, highlighted: highlightedSet, disabled: colorSet.disabledSet(for: style))
	}
}

private class ThemeColorPair : NSObject {
	@objc public var foreground: UIColor
	@objc public var background: UIColor

	public init(foreground fgColor: UIColor, background bgColor: UIColor) {
		foreground = fgColor
		background = bgColor
	}
}

private class ThemeColorPairCollection : NSObject {
	@objc public var normal : ThemeColorPair
	@objc public var highlighted : ThemeColorPair
	@objc public var disabled : ThemeColorPair

	public init(fromPair: ThemeColorPair) {
		normal = fromPair
		highlighted = ThemeColorPair(foreground: fromPair.foreground, background: fromPair.background.lighter(0.25))
		disabled = ThemeColorPair(foreground: fromPair.foreground, background: fromPair.background.lighter(0.25))
	}

	public init(fromPairCollection: ThemeColorPairCollection) {
		normal = ThemeColorPair(foreground: fromPairCollection.normal.foreground, background: fromPairCollection.normal.background)
		highlighted = ThemeColorPair(foreground: fromPairCollection.highlighted.foreground, background: fromPairCollection.highlighted.background)
		disabled = ThemeColorPair(foreground: fromPairCollection.disabled.foreground, background: fromPairCollection.disabled.background)
	}
}

private class ThemeColorCollection : NSObject {
	@objc public var backgroundColor : UIColor?
	@objc public var labelColor : UIColor
	@objc public var secondaryLabelColor : UIColor
	@objc public var symbolColor : UIColor
	@objc public var tintColor : UIColor?

	@objc public var filledColorPairCollection : ThemeColorPairCollection

	public init(backgroundColor bgColor : UIColor?, tintColor tntColor: UIColor?, labelColor lblColor : UIColor, secondaryLabelColor secLabelColor: UIColor, symbolColor symColor: UIColor, filledColorPairCollection filColorPairCollection: ThemeColorPairCollection) {
		backgroundColor = bgColor
		labelColor = lblColor
		symbolColor = symColor
		secondaryLabelColor = secLabelColor
		tintColor = tntColor
		filledColorPairCollection = filColorPairCollection
	}
}

public enum ThemeCollectionStyle : String, CaseIterable {
	case dark
	case light

	public var name : String {
		switch self {
			case .dark:	return "Dark".localized
			case .light:	return "Light".localized
		}
	}

	public var userInterfaceStyle : UIUserInterfaceStyle {
		switch self {
			case .dark: return .dark
			case .light: return .light
		}
	}
}

public class ThemeCollection : NSObject {
	@objc var identifier : String = UUID().uuidString

	// MARK: - ThemeCSS
	public var css: ThemeCSS

	// MARK: - Default Collection
	static public var defaultCollection : ThemeCollection = {
		let collection = ThemeCollection()

		/*
		Log.log("%@", collection.value(forKeyPath: "tintColor") as! CVarArg)
		Log.log("%@", collection.value(forKeyPath: "toolBarColorCollection.filledColorPairCollection.normal.background") as! CVarArg)
		Log.log("%@", collection.value(forKeyPath: "toolBarColorCollection.filledColorPairCollection.normal.backgrounds") as! CVarArg)
		*/

		return (collection)
	}()

	static var darkCollection : ThemeCollection = {
		let collection = ThemeCollection()

		return (collection)
	}()

	private static func generateColorPairs(with baseSelectors:[ThemeCSSSelector], foregroundColor: UIColor, backgroundColor: UIColor) -> [ThemeCSSRecord] {
		var disabledSelectors = baseSelectors
		disabledSelectors.append(.disabled)
		var highlightedSelectors = baseSelectors
		highlightedSelectors.append(.highlighted)

		let colorPairs: [ThemeCSSRecord] = [
			ThemeCSSRecord(selectors: baseSelectors,		property: .stroke, value: foregroundColor),
			ThemeCSSRecord(selectors: baseSelectors,		property: .fill,   value: backgroundColor),

			ThemeCSSRecord(selectors: highlightedSelectors,		property: .stroke, value: foregroundColor),
			ThemeCSSRecord(selectors: highlightedSelectors,		property: .fill,   value: backgroundColor.lighter(0.25)),

			ThemeCSSRecord(selectors: disabledSelectors,		property: .stroke, value: foregroundColor),
			ThemeCSSRecord(selectors: disabledSelectors,		property: .fill,   value: backgroundColor.lighter(0.25))
		]

		return colorPairs
	}

	private static func generateColorPairs(with baseSelectors:[ThemeCSSSelector], from pairCollection: ThemeColorPairCollection) -> [ThemeCSSRecord] {
		var disabledSelectors = baseSelectors
		disabledSelectors.append(.disabled)
		var highlightedSelectors = baseSelectors
		highlightedSelectors.append(.highlighted)

		let colorPairs: [ThemeCSSRecord] = [
			ThemeCSSRecord(selectors: baseSelectors,		property: .stroke, value: pairCollection.normal.foreground),
			ThemeCSSRecord(selectors: baseSelectors,		property: .fill,   value: pairCollection.normal.background),

			ThemeCSSRecord(selectors: highlightedSelectors,		property: .stroke, value: pairCollection.highlighted.foreground),
			ThemeCSSRecord(selectors: highlightedSelectors,		property: .fill,   value: pairCollection.highlighted.background),

			ThemeCSSRecord(selectors: disabledSelectors,		property: .stroke, value: pairCollection.disabled.foreground),
			ThemeCSSRecord(selectors: disabledSelectors,		property: .fill,   value: pairCollection.disabled.background)
		]

		return colorPairs
	}

	init(darkBrandColor darkColor: UIColor, lightBrandColor lightColor: UIColor, style: ThemeCollectionStyle = .dark, customColors: NSDictionary? = nil, genericColors: NSDictionary? = nil, interfaceStyles: NSDictionary? = nil) {
		var logoFillColor : UIColor?

		self.css = ThemeCSS()

		var interfaceStyle : UIUserInterfaceStyle = .unspecified
		var keyboardAppearance : UIKeyboardAppearance = .default
		var backgroundBlurEffectStyle : UIBlurEffect.Style = .regular

		var statusBarStyle : UIStatusBarStyle
		var barStyle : UIBarStyle

		let darkBrandColor = darkColor
		let lightBrandColor = lightColor

		/*
			Cells:
			- cell		-> lightCell
			- groupedCell	-> lightGroupedCell
			- sidebarCell	-> darkCell
			- accountCell	-> darkGroupedCell

			Bars:
			- topBar
			- sidebarTopBar

			- bottomBar
			- sidebarBottomBar

			Buttons:
			- plain
			- bordered
			- confirm
			- ..
		*/
		var lightBrandSet = ThemeColorSet.from(backgroundColor: lightColor, tintColor: darkColor, for: style.userInterfaceStyle)
		let darkBrandSet = ThemeColorSet.from(backgroundColor: darkColor, tintColor: lightColor, for: style.userInterfaceStyle)

		let styleTraitCollection = UITraitCollection(userInterfaceStyle: interfaceStyle)

		var cellSet: ThemeColorSet
		var groupedCellSet: ThemeColorSet
		var collectionBackgroundColor: UIColor
		var groupedCollectionBackgroundColor: UIColor
		var accountCellSet: ThemeColorSet
		var sidebarAccountCellSet: ThemeColorSet

		var navigationBarSet: ThemeColorSet
		var toolbarSet: ThemeColorSet
		var contentNavigationBarSet: ThemeColorSet
		var contentToolbarSet: ThemeColorSet

		var cellStateSet: ThemeColorStateSet
		var groupedCellStateSet: ThemeColorStateSet
		var sidebarCellStateSet: ThemeColorStateSet

		var sidebarLogoIconColor: UIColor
		var sidebarLogoLabel: UIColor
		var iconSymbolColor: UIColor

		let tintColor: UIColor = lightBrandColor

		var separatorColor: UIColor = UIColor.opaqueSeparator.resolvedColor(with: styleTraitCollection)
		var sectionHeaderColor: UIColor
		var sectionFooterColor: UIColor
		var groupedSectionHeaderColor: UIColor
		var groupedSectionFooterColor: UIColor

		var moreHeaderBackgroundColor: UIColor

		let lightBrandColors = ThemeColorCollection(
			backgroundColor: lightColor,
			tintColor: UIColor.white,
			labelColor: UIColor.white,
			secondaryLabelColor: UIColor.lightGray,
			symbolColor: UIColor.white,
			filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
		)

		let neutralColors = lightBrandColors.filledColorPairCollection
		let purchaseColors = ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: lightBrandColors.labelColor, background: lightBrandColor))
		purchaseColors.disabled.background = purchaseColors.disabled.background.greyscale

		var tokenForegroundColor = lightBrandColor
		var tokenBackgroundColor = UIColor(white: 0, alpha: 0.1)

		// Table view
		var progressColors : ThemeColorPair

		// Styles
		switch style {
			case .dark:
				// Interface style
				interfaceStyle = .dark
				keyboardAppearance = .dark
				backgroundBlurEffectStyle = .dark
				statusBarStyle = .lightContent
				barStyle = .black

				// --

				lightBrandSet.labelColor = .white
				lightBrandSet.secondaryLabelColor = .white
				lightBrandSet.iconColor = .white

				accountCellSet = lightBrandSet
				sidebarAccountCellSet = ThemeColorSet.from(backgroundColor: .init(hex: 0, alpha: 0.5), tintColor: lightBrandColor, for: interfaceStyle)

				navigationBarSet = darkBrandSet
				toolbarSet = darkBrandSet

				cellSet = ThemeColorSet.from(backgroundColor: UIColor(hex: 0), tintColor: lightColor, for: interfaceStyle)
				cellStateSet = ThemeColorStateSet.from(colorSet: cellSet, for: interfaceStyle)
				collectionBackgroundColor = darkColor.darker(0.1)

				groupedCellSet = ThemeColorSet.from(backgroundColor: darkColor, tintColor: lightColor, for: interfaceStyle)
				groupedCellStateSet = ThemeColorStateSet.from(colorSet: groupedCellSet, for: interfaceStyle)
				groupedCollectionBackgroundColor = navigationBarSet.backgroundColor.darker(0.3)

				contentNavigationBarSet = cellSet
				contentToolbarSet = cellSet

				sidebarCellStateSet = ThemeColorStateSet.from(colorSet: darkBrandSet, for: interfaceStyle)
				sidebarCellStateSet.selected.backgroundColor = sidebarCellStateSet.regular.labelColor
				sidebarCellStateSet.selected.labelColor = sidebarCellStateSet.regular.backgroundColor
				sidebarCellStateSet.selected.iconColor = sidebarCellStateSet.regular.backgroundColor

				sidebarLogoIconColor = .white
				sidebarLogoLabel = .white
				iconSymbolColor = lightColor

				separatorColor = .darkGray

				sectionHeaderColor = .white
				sectionFooterColor = .lightGray
				groupedSectionHeaderColor = .lightGray
				groupedSectionFooterColor = .lightGray

				moreHeaderBackgroundColor = darkColor.lighter(0.05)

				// --

				// Bars
				tokenForegroundColor = lightBrandColor
				tokenBackgroundColor = UIColor(white: 1, alpha: 0.1)

				// Table view
				// tableRowBorderColor = UIColor.white.withAlphaComponent(0.1)

				// Progress
				progressColors = ThemeColorPair(foreground: lightBrandColor, background: lightBrandColor.withAlphaComponent(0.3))

				// Logo fill color
				let logoColor : UIColor? = UIColor.white
				logoFillColor = logoColor

			case .light:
				// Interface style
				interfaceStyle = .light
				keyboardAppearance = .light
				backgroundBlurEffectStyle = .light
				statusBarStyle = .darkContent
				barStyle = .default

				// --

				accountCellSet = darkBrandSet
				sidebarAccountCellSet = ThemeColorSet.from(backgroundColor: .white, tintColor: .white, for: interfaceStyle)

				navigationBarSet = ThemeColorSet.from(backgroundColor: .systemBackground.resolvedColor(with: styleTraitCollection), tintColor: lightColor, for: interfaceStyle)
				toolbarSet = navigationBarSet

				cellSet = ThemeColorSet.from(backgroundColor: .systemBackground.resolvedColor(with: styleTraitCollection), tintColor: lightColor, for: interfaceStyle)
				cellStateSet = ThemeColorStateSet.from(colorSet: cellSet, for: interfaceStyle)
				collectionBackgroundColor = cellSet.backgroundColor

				groupedCellSet = cellSet
				groupedCellStateSet = ThemeColorStateSet.from(colorSet: groupedCellSet, for: interfaceStyle)
				groupedCollectionBackgroundColor = .systemGroupedBackground.resolvedColor(with: styleTraitCollection)

				contentNavigationBarSet = cellSet
				contentToolbarSet = cellSet

				sidebarCellStateSet = ThemeColorStateSet.from(colorSet: lightBrandSet, for: .light)
				sidebarCellStateSet.regular.backgroundColor = .secondarySystemBackground.resolvedColor(with: styleTraitCollection)
				sidebarCellStateSet.selected.labelColor = .white
				sidebarCellStateSet.selected.iconColor = .white
				sidebarCellStateSet.selected.backgroundColor = darkBrandColor

				sidebarLogoIconColor = darkBrandColor
				sidebarLogoLabel = darkBrandColor
				iconSymbolColor = darkColor

				sectionHeaderColor = .label.resolvedColor(with: styleTraitCollection)
				sectionFooterColor = .secondaryLabel.resolvedColor(with: styleTraitCollection)
				groupedSectionHeaderColor = .secondaryLabel.resolvedColor(with: styleTraitCollection)
				groupedSectionFooterColor = .secondaryLabel.resolvedColor(with: styleTraitCollection)

				moreHeaderBackgroundColor = cellSet.backgroundColor

				// --

				// Progress
				progressColors = ThemeColorPair(foreground: lightBrandColor, background: UIColor.lightGray.withAlphaComponent(0.3))

				// Logo fill color
				let logoColor : UIColor? = UIColor.lightGray
				logoFillColor = logoColor
		}

		// Fixed colors
		let primaryLabelColor = cellSet.labelColor // UIColor.label.resolvedColor(with: styleTraitCollection)
		let secondaryLabelColor = cellSet.secondaryLabelColor // UIColor.secondaryLabel.resolvedColor(with: styleTraitCollection)
		let tertiaryLabelColor = cellSet.secondaryLabelColor // UIColor.tertiaryLabel.resolvedColor(with: styleTraitCollection)
		let placeholderTextColor = cellSet.secondaryLabelColor // UIColor.placeholderText.resolvedColor(with: styleTraitCollection)

		let primaryBackgroundColor = UIColor.systemBackground.resolvedColor(with: styleTraitCollection)
		let secondaryBackgroundColor = UIColor.secondarySystemBackground.resolvedColor(with: styleTraitCollection)
		let tertiaryBackgroundColor = UIColor.tertiarySystemBackground.resolvedColor(with: styleTraitCollection)

		let progressForegroundColor = progressColors.foreground
		let progressBackgroundColor = progressColors.background

		let favoriteEnabledColor = UIColor(hex: 0xFFCC00)
		let favoriteDisabledColor = UIColor(hex: 0x7C7C7C)

		// CSS
		css.add(records: [
			// Global styles
			// - Interface Style
			ThemeCSSRecord(selectors: [.all], 			   	property: .style, value: interfaceStyle),

			// - Blur Effect Style
			ThemeCSSRecord(selectors: [.all], 			   	property: .blurEffectStyle, value: backgroundBlurEffectStyle),

			// - Status Bar
			ThemeCSSRecord(selectors: [.all], 			   	property: .statusBarStyle, value: statusBarStyle),

			// - Bar
			ThemeCSSRecord(selectors: [.all], 			   	property: .barStyle, value: barStyle),

			// - Activity Indicator
			ThemeCSSRecord(selectors: [.all], 			   	property: .activityIndicatorStyle, value: UIActivityIndicatorView.Style.medium),

			// General
			// - Seperator
			ThemeCSSRecord(selectors: [.separator], 			property: .fill,  value: separatorColor),

			// - Navigation Bar
			ThemeCSSRecord(selectors: [.navigationBar],			property: .stroke, value: navigationBarSet.tintColor),
			ThemeCSSRecord(selectors: [.navigationBar, .label],		property: .stroke, value: navigationBarSet.labelColor),
			ThemeCSSRecord(selectors: [.navigationBar],			property: .fill,   value: navigationBarSet.backgroundColor),

			// - Toolbar
			ThemeCSSRecord(selectors: [.toolbar],				property: .stroke, value: toolbarSet.tintColor),
			ThemeCSSRecord(selectors: [.toolbar],				property: .fill,   value: toolbarSet.backgroundColor),

			// - Progress
			ThemeCSSRecord(selectors: [.progress], 				property: .fill,  value: progressBackgroundColor),
			ThemeCSSRecord(selectors: [.progress], 				property: .stroke,value: progressForegroundColor),
			ThemeCSSRecord(selectors: [.progress, .button],			property: .fill,  value: tintColor),

			// - Cells
			ThemeCSSRecord(selectors: [.cell, .sectionHeader],		property: .stroke, value: sectionHeaderColor),

			// - Modal
			ThemeCSSRecord(selectors: [.modal],     	    	   	property: .fill,   value: cellSet.backgroundColor),
			ThemeCSSRecord(selectors: [.modal],     	    	   	property: .stroke, value: cellSet.labelColor),

			// - Collection View
			ThemeCSSRecord(selectors: [.collection],     	    	   	property: .fill,   value: cellStateSet.regular.backgroundColor),
			ThemeCSSRecord(selectors: [.collection, .highlighted, .cell],  	property: .fill,   value: cellStateSet.highlighted.backgroundColor),
			ThemeCSSRecord(selectors: [.collection, .cell], 	   	property: .stroke, value: cellStateSet.regular.tintColor),
			ThemeCSSRecord(selectors: [.collection, .cell,.title], 		property: .stroke, value: cellStateSet.regular.labelColor),
			ThemeCSSRecord(selectors: [.collection, .cell,.segments], 	property: .stroke, value: cellStateSet.regular.secondaryLabelColor),
			ThemeCSSRecord(selectors: [.collection, .cell,.segments], 	property: .fill,   value: UIColor.clear),
			ThemeCSSRecord(selectors: [.collection, .cell,.segments,.icon], property: .stroke, value: cellStateSet.regular.secondaryLabelColor),
			ThemeCSSRecord(selectors: [.collection, .cell,.segments,.title],property: .stroke, value: cellStateSet.regular.secondaryLabelColor),
			ThemeCSSRecord(selectors: [.collection, .sectionFooter], 	property: .stroke, value: sectionFooterColor),
			ThemeCSSRecord(selectors: [.collection, .cell], 	   	property: .fill,   value: cellStateSet.regular.backgroundColor),

			// - Table View
			ThemeCSSRecord(selectors: [.table],     	    	   	property: .fill,   value: cellStateSet.regular.backgroundColor),
			ThemeCSSRecord(selectors: [.grouped, .table],  	    	   	property: .fill,   value: groupedCollectionBackgroundColor),
			ThemeCSSRecord(selectors: [.insetGrouped, .table],    	   	property: .fill,   value: groupedCollectionBackgroundColor),

			ThemeCSSRecord(selectors: [.table, .cell],    			property: .stroke, value: cellStateSet.regular.tintColor), // tableRowColors.tintColor),
			ThemeCSSRecord(selectors: [.table, .cell],     	    	   	property: .fill,   value: cellStateSet.regular.backgroundColor),
			ThemeCSSRecord(selectors: [.table, .highlighted, .cell],     	property: .fill,   value: cellStateSet.highlighted.backgroundColor),

			ThemeCSSRecord(selectors: [.grouped, .table, .cell],			property: .stroke, value: groupedCellStateSet.regular.tintColor), // tableRowColors.tintColor),
			ThemeCSSRecord(selectors: [.grouped, .table, .cell, .label],		property: .stroke, value: groupedCellStateSet.regular.labelColor),
			ThemeCSSRecord(selectors: [.grouped, .table, .cell],			property: .fill,   value: groupedCellStateSet.regular.backgroundColor),
			ThemeCSSRecord(selectors: [.grouped, .table, .highlighted, .cell],	property: .fill,   value: groupedCellStateSet.highlighted.backgroundColor),

			ThemeCSSRecord(selectors: [.grouped, .table, .sectionHeader],    	property: .stroke, value: groupedSectionHeaderColor),
			ThemeCSSRecord(selectors: [.grouped, .table, .sectionFooter],    	property: .stroke, value: groupedSectionFooterColor),

			ThemeCSSRecord(selectors: [.insetGrouped, .table, .cell],		property: .stroke, value: groupedCellStateSet.regular.tintColor), // tableRowColors.tintColor),
			ThemeCSSRecord(selectors: [.insetGrouped, .table, .cell],		property: .fill,   value: groupedCellStateSet.regular.backgroundColor),
			ThemeCSSRecord(selectors: [.insetGrouped, .table, .highlighted, .cell],	property: .fill,   value: groupedCellStateSet.highlighted.backgroundColor),

			ThemeCSSRecord(selectors: [.table, .sectionHeader],    			property: .stroke, value: sectionHeaderColor),
			ThemeCSSRecord(selectors: [.table, .sectionFooter],    			property: .stroke, value: sectionFooterColor),

			ThemeCSSRecord(selectors: [.table, .icon],    				property: .stroke, value: cellStateSet.regular.iconColor),
			ThemeCSSRecord(selectors: [.table, .label, .primary],    		property: .stroke, value: cellStateSet.regular.labelColor),
			ThemeCSSRecord(selectors: [.table, .label, .secondary], 		property: .stroke, value: cellStateSet.regular.secondaryLabelColor),
			ThemeCSSRecord(selectors: [.table, .label, .highlighted, .primary],    	property: .stroke, value: cellStateSet.highlighted.labelColor),
			ThemeCSSRecord(selectors: [.table, .label, .highlighted, .secondary], 	property: .stroke, value: cellStateSet.highlighted.secondaryLabelColor),

			// - Accessories
			ThemeCSSRecord(selectors: [.accessory], 			property: .stroke, value: cellStateSet.regular.secondaryLabelColor),
			ThemeCSSRecord(selectors: [.accessory, .accept],		property: .stroke, value: UIColor.systemGreen),
			ThemeCSSRecord(selectors: [.accessory, .decline],		property: .stroke, value: UIColor.systemRed),

			// - Segment View
			ThemeCSSRecord(selectors: [.segments], 				property: .fill,   value: UIColor.clear),
			ThemeCSSRecord(selectors: [.segments, .icon], 			property: .stroke, value: cellSet.iconColor),
			ThemeCSSRecord(selectors: [.segments, .title],			property: .stroke, value: cellSet.secondaryLabelColor),

			ThemeCSSRecord(selectors: [.segments, .token],			property: .fill,   value: tokenBackgroundColor),
			ThemeCSSRecord(selectors: [.segments, .token, .icon],		property: .stroke, value: tokenForegroundColor),
			ThemeCSSRecord(selectors: [.segments, .token, .title],		property: .stroke, value: tokenForegroundColor),

			// - Messages
			ThemeCSSRecord(selectors: [.infoBox, .background],		property: .fill, value: groupedCollectionBackgroundColor),
			ThemeCSSRecord(selectors: [.infoBox, .icon],			property: .fill, value: secondaryLabelColor),
			ThemeCSSRecord(selectors: [.infoBox, .subtitle],		property: .fill, value: secondaryLabelColor),

			ThemeCSSRecord(selectors: [.title],				property: .stroke, value: primaryLabelColor),
			ThemeCSSRecord(selectors: [.subtitle],				property: .stroke, value: secondaryLabelColor),
			ThemeCSSRecord(selectors: [.message],				property: .stroke, value: tertiaryLabelColor),

			ThemeCSSRecord(selectors: [.primary],				property: .stroke, value: primaryLabelColor),
			ThemeCSSRecord(selectors: [.secondary],				property: .stroke, value: secondaryLabelColor),
			ThemeCSSRecord(selectors: [.tertiary],				property: .stroke, value: tertiaryLabelColor),

			// - Saved Search
			ThemeCSSRecord(selectors: [.savedSearch],			property: .fill, value: groupedCollectionBackgroundColor),
			ThemeCSSRecord(selectors: [.savedSearch, .cell],		property: .fill, value: groupedCollectionBackgroundColor),

			// - Fills
			ThemeCSSRecord(selectors: [.primary],				property: .fill, value: primaryBackgroundColor),
			ThemeCSSRecord(selectors: [.secondary],				property: .fill, value: secondaryBackgroundColor),
			ThemeCSSRecord(selectors: [.tertiary],				property: .fill, value: tertiaryBackgroundColor),

			// - Text Field
			ThemeCSSRecord(selectors: [.textField],				property: .fill,   value: collectionBackgroundColor), // Background color
			ThemeCSSRecord(selectors: [.textField, .label],			property: .stroke, value: cellSet.labelColor), // Text color
			ThemeCSSRecord(selectors: [.textField, .disabled, .label],	property: .stroke, value: cellSet.secondaryLabelColor), // Disabled text color
			ThemeCSSRecord(selectors: [.textField, .placeholder],		property: .stroke, value: placeholderTextColor), // Text field placeholder

			// - Search Field
			ThemeCSSRecord(selectors: [.textField, .searchField],			property: .stroke, value: lightBrandColor), // Search tint color (UI elements other than text)
			ThemeCSSRecord(selectors: [.textField, .searchField, .label],		property: .stroke, value: primaryLabelColor), // Search text color

			// - Slider
			ThemeCSSRecord(selectors: [.slider], 				property: .stroke, value: lightBrandColor),

			// - Buttons + Popups
			ThemeCSSRecord(selectors: [.button],				property: .stroke, value: lightBrandColor),
			ThemeCSSRecord(selectors: [.popupButton],			property: .stroke, value: lightBrandColor),

			// - Label styles
			ThemeCSSRecord(selectors: [.label, .destructive],		property: .stroke, value: UIColor.red),
			ThemeCSSRecord(selectors: [.label, .warning],			property: .stroke, value: UIColor(hex: 0xF2994A)),
			ThemeCSSRecord(selectors: [.label, .error],			property: .stroke, value: UIColor(hex: 0xEB5757)),
			ThemeCSSRecord(selectors: [.label, .success],			property: .stroke, value: UIColor(hex: 0x27AE60))
		])

		// - Fill styles
		css.add(records: ThemeCollection.generateColorPairs(with: [.destructive], foregroundColor: .white, backgroundColor: .red))
		css.add(records: ThemeCollection.generateColorPairs(with: [.confirm], 	  foregroundColor: .white, backgroundColor: UIColor(hex: 0x1AC763)))
		css.add(records: ThemeCollection.generateColorPairs(with: [.cancel], 	  foregroundColor: .white, backgroundColor: lightBrandColor))
		css.add(records: ThemeCollection.generateColorPairs(with: [.proceed], 	  foregroundColor: .white, backgroundColor: lightBrandColor))
		css.add(records: ThemeCollection.generateColorPairs(with: [.info], 	  foregroundColor: .white, backgroundColor: lightBrandColor))
		css.add(records: ThemeCollection.generateColorPairs(with: [.warning], 	  foregroundColor: .black, backgroundColor: .systemYellow))

		css.add(records: ThemeCollection.generateColorPairs(with: [.purchase], 	  from: purchaseColors))

		// - Pass code fill style
		css.add(records: ThemeCollection.generateColorPairs(with: [.digit], 	  from: neutralColors))

		css.add(records: [
			ThemeCSSRecord(selectors: [.passcode],				property: .fill,   value: collectionBackgroundColor),
			ThemeCSSRecord(selectors: [.passcode, .title],			property: .stroke, value: primaryLabelColor),
			ThemeCSSRecord(selectors: [.passcode, .disabled, .title],	property: .stroke, value: secondaryLabelColor),
			ThemeCSSRecord(selectors: [.passcode, .code],			property: .stroke, value: neutralColors.normal.background),
			ThemeCSSRecord(selectors: [.passcode, .disabled, .code],	property: .stroke, value: primaryLabelColor),
			ThemeCSSRecord(selectors: [.passcode, .subtitle],		property: .stroke, value: secondaryLabelColor),
			ThemeCSSRecord(selectors: [.passcode, .disabled, .subtitle],	property: .stroke, value: tertiaryLabelColor),

			// - Alert View Controller
			ThemeCSSRecord(selectors: [.alert],				property: .stroke, value: tintColor),

			// - Action / Drop target (plain) fill style
			ThemeCSSRecord(selectors: [.action],				property: .fill, value: UIColor(white: 0, alpha: 0.05)),
			ThemeCSSRecord(selectors: [.action, .highlighted],		property: .fill, value: UIColor(white: 0, alpha: 0.10)),

			// - Drive Header
			ThemeCSSRecord(selectors: [.header, .drive, .cover],		property: .fill, value: lightBrandColor),

			// - Expandable Resource Cell
			ThemeCSSRecord(selectors: [.expandable],			property: .fill,   value: collectionBackgroundColor),
			ThemeCSSRecord(selectors: [.expandable, .button],		property: .stroke, value: tintColor),
			ThemeCSSRecord(selectors: [.expandable, .textView],		property: .fill,   value: collectionBackgroundColor),
			ThemeCSSRecord(selectors: [.expandable, .textView],		property: .stroke, value: secondaryLabelColor),
			ThemeCSSRecord(selectors: [.expandable, .shadow],		property: .fill,   value: cellSet.labelColor),

			// - Location Bar
			ThemeCSSRecord(selectors: [.locationBar],			property: .fill, value: cellSet.backgroundColor),

			// - Keyboard
			ThemeCSSRecord(selectors: [.all],				property: .keyboardAppearance, value: keyboardAppearance),

			// - Account Cell
			ThemeCSSRecord(selectors: [.account],				property: .fill,   value: accountCellSet.backgroundColor),
			ThemeCSSRecord(selectors: [.account, .title],			property: .stroke, value: accountCellSet.labelColor),
			ThemeCSSRecord(selectors: [.account, .description],		property: .stroke, value: accountCellSet.secondaryLabelColor),
			ThemeCSSRecord(selectors: [.account, .disconnect],		property: .stroke, value: accountCellSet.tintColor),
			ThemeCSSRecord(selectors: [.account, .disconnect],		property: .fill,   value: accountCellSet.labelColor),

			// - Location Picker
			ThemeCSSRecord(selectors: [.locationPicker, .collection, .accountList], property: .fill, value: groupedCollectionBackgroundColor),
			ThemeCSSRecord(selectors: [.locationPicker, .collection, .accountList, .cell], property: .fill, value: UIColor.white),
			ThemeCSSRecord(selectors: [.locationPicker, .collection, .accountList, .account], property: .fill, value: darkBrandColor),

			// - More card header
			ThemeCSSRecord(selectors: [.more, .header], 			property: .fill,   value: moreHeaderBackgroundColor),
			ThemeCSSRecord(selectors: [.more, .collection], 		property: .fill,   value: groupedCellStateSet),
			ThemeCSSRecord(selectors: [.more, .insetGrouped, .table, .cell, .proceed],	property: .stroke, value: UIColor.white),

			ThemeCSSRecord(selectors: [.more, .favorite],			property: .stroke, value: favoriteEnabledColor),
			ThemeCSSRecord(selectors: [.more, .favorite, .disabled],	property: .stroke, value: favoriteDisabledColor),

			// - TVG icon colors
			ThemeCSSRecord(selectors: [.vectorImage, .folderFillColor], 	property: .fill, value: iconSymbolColor),
			ThemeCSSRecord(selectors: [.vectorImage, .fileFillColor], 	property: .fill, value: iconSymbolColor),
			ThemeCSSRecord(selectors: [.vectorImage, .logoFillColor], 	property: .fill, value: logoFillColor ?? UIColor.white),
			ThemeCSSRecord(selectors: [.vectorImage, .iconFillColor], 	property: .fill, value: iconSymbolColor),
			ThemeCSSRecord(selectors: [.vectorImage, .symbolFillColor], 	property: .fill, value: iconSymbolColor),

			// Side Bar
			// - Interface Style
			ThemeCSSRecord(selectors: [.sidebar], 			   	property: .style, value: UIUserInterfaceStyle.light),

			// - Status Bar
			ThemeCSSRecord(selectors: [.sidebar], 			   	property: .statusBarStyle, value: statusBarStyle),

			// - Collection View
			ThemeCSSRecord(selectors: [.sidebar, .collection, .cell],  	property: .fill,   value: sidebarCellStateSet.regular.backgroundColor),
			ThemeCSSRecord(selectors: [.sidebar, .collection],  	   	property: .fill,   value: sidebarCellStateSet.regular.backgroundColor),
			ThemeCSSRecord(selectors: [.sidebar, .collection, .cell], 	property: .stroke, value: sidebarCellStateSet.regular.labelColor),
			// ThemeCSSRecord(selectors: [.sidebar, .collection, .label], 	property: .stroke, value: sidebarCellStateSet.regular.labelColor),
			// ThemeCSSRecord(selectors: [.sidebar, .collection, .icon],  	property: .stroke, value: sidebarCellStateSet.regular.labelColor),

			ThemeCSSRecord(selectors: [.sidebar, .collection, .selected, .cell],  property: .stroke, value: sidebarCellStateSet.selected.labelColor),
			ThemeCSSRecord(selectors: [.sidebar, .collection, .selected, .cell],  property: .fill, value: sidebarCellStateSet.selected.backgroundColor),

			// - Account Cell
			ThemeCSSRecord(selectors: [.sidebar, .account],			property: .fill,   value: sidebarAccountCellSet.backgroundColor),
			ThemeCSSRecord(selectors: [.sidebar, .account, .title],		property: .stroke, value: sidebarAccountCellSet.labelColor),
			ThemeCSSRecord(selectors: [.sidebar, .account, .description],	property: .stroke, value: sidebarAccountCellSet.secondaryLabelColor),
			ThemeCSSRecord(selectors: [.sidebar, .account, .disconnect],	property: .stroke, value: sidebarAccountCellSet.tintColor),
			ThemeCSSRecord(selectors: [.sidebar, .account, .disconnect],	property: .fill,   value: sidebarAccountCellSet.labelColor),

			// - Navigation Bar
			ThemeCSSRecord(selectors: [.sidebar, .navigationBar],		property: .stroke, value: lightColor),
			ThemeCSSRecord(selectors: [.sidebar, .navigationBar],		property: .fill,   value: nil),
			ThemeCSSRecord(selectors: [.sidebar, .navigationBar, .logo],	property: .stroke, value: sidebarLogoIconColor),
			ThemeCSSRecord(selectors: [.sidebar, .navigationBar, .logo, .label],property: .stroke, value: sidebarLogoLabel),

			// - Toolbar
			ThemeCSSRecord(selectors: [.sidebar, .toolbar],			property: .fill,   value: sidebarCellStateSet.regular.backgroundColor),
			ThemeCSSRecord(selectors: [.sidebar, .toolbar],			property: .stroke, value: lightColor),

			// Content Area
			ThemeCSSRecord(selectors: [.content],				property: .fill,   value: collectionBackgroundColor),

			// - Navigation Bar
			ThemeCSSRecord(selectors: [.content, .navigationBar],			property: .fill,   value: contentNavigationBarSet.backgroundColor),
			ThemeCSSRecord(selectors: [.content, .navigationBar],			property: .stroke, value: contentNavigationBarSet.tintColor),
			ThemeCSSRecord(selectors: [.content, .navigationBar, .label, .title],	property: .stroke, value: contentNavigationBarSet.labelColor),

			// - Toolbar
			ThemeCSSRecord(selectors: [.content, .toolbar],				property: .stroke, value: contentToolbarSet.tintColor),
			ThemeCSSRecord(selectors: [.content, .toolbar],				property: .fill,   value: contentToolbarSet.backgroundColor),

			// - Location Bar
			ThemeCSSRecord(selectors: [.content, .toolbar, .locationBar, .segments, .item, .plain],		property: .stroke, value: contentToolbarSet.tintColor),
			ThemeCSSRecord(selectors: [.content, .toolbar, .locationBar, .segments, .item, .separator],	property: .stroke, value: contentToolbarSet.secondaryLabelColor),
			ThemeCSSRecord(selectors: [.content, .toolbar, .locationBar, .segments, .item, .separator],	property: .fill,   value: contentToolbarSet.backgroundColor),
			ThemeCSSRecord(selectors: [.content, .toolbar, .locationBar],					property: .fill,   value: contentToolbarSet.backgroundColor)
		])

//		{
//			<key>sidebar.collection.icon.stroke</key>
//			<string>#ffffff</string>
//
//			<key>css.0</key><string>sidebar.collection.icon.stroke=#ffffff</string>
//			<key>css.1</key><string>sidebar.collection.icon.stroke=#ffffff</string>
//
//			ThemeCSSRecord(selectors: [.sidebar, .collection, .icon],  property: .stroke, value: UIColor.white)
//
//		}
	}

	convenience override init() {
		self.init(darkBrandColor: UIColor(hex: 0x1D293B), lightBrandColor: UIColor(hex: 0x468CC8))
	}

	// MARK: - Icon colors
	var _iconColors: [String:String]?
	public var iconColors: [String:String] {
		if _iconColors == nil {
			_iconColors = [:]

			_iconColors?["folderFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .folderFillColor], for: nil)?.hexString()
			_iconColors?["fileFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .fileFillColor], for: nil)?.hexString()
			_iconColors?["logoFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .logoFillColor], for: nil)?.hexString()
			_iconColors?["iconFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .iconFillColor], for: nil)?.hexString()
			_iconColors?["symbolFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .symbolFillColor], for: nil)?.hexString()
		}

		return _iconColors ?? [:]
	}
}

extension ThemeCSSSelector {
	static let folderFillColor = ThemeCSSSelector(rawValue: "folderFillColor")
	static let fileFillColor = ThemeCSSSelector(rawValue: "fileFillColor")
	static let logoFillColor = ThemeCSSSelector(rawValue: "logoFillColor")
	static let iconFillColor = ThemeCSSSelector(rawValue: "iconFillColor")
	static let symbolFillColor = ThemeCSSSelector(rawValue: "symbolFillColor")
}

extension ThemeCollection {
	func navigationBarAppearance(navigationBar: UINavigationBar, scrollEdge: Bool = false) -> UINavigationBarAppearance {
		let appearance = UINavigationBarAppearance()

		appearance.configureWithOpaqueBackground()

		if let labelColor = css.getColor(.stroke, selectors: [.label], for: navigationBar) {
			appearance.titleTextAttributes = [ .foregroundColor : labelColor  ]
			appearance.largeTitleTextAttributes = [ .foregroundColor : labelColor  ]
		}

		appearance.backgroundColor = css.getColor(.fill, for: navigationBar)

		if scrollEdge {
			appearance.shadowColor = .clear
		}

		return appearance
	}
}
