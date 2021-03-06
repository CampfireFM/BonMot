//
//  AdaptableTextContainer.swift
//  BonMot
//
//  Created by Brian King on 7/19/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

import UIKit

/// A protocol to update the text style contained by the object. This can be
/// triggered manually in `traitCollectionDidChange(_:)`. Any `UIViewController`
/// or `UIView` that conforms to this protocol will be informed of content size
/// category changes if `UIApplication.enableAdaptiveContentSizeMonitor()` is called.
@objc(BONAdaptableTextContainer)
public protocol AdaptableTextContainer {

    /// Update the text style contained by the object in response to a trait
    /// collection change.
    ///
    /// - parameter traitCollection: The new trait collection.
    @objc(bon_updateTextForTraitCollection:)
    func adaptText(forTraitCollection traitCollection: UITraitCollection)

}

extension UILabel: AdaptableTextContainer {

    /// Adapt `attributedText` to the specified trait collection.
    ///
    /// - parameter traitCollection: The new trait collection.
    @objc(bon_updateTextForTraitCollection:)
    public func adaptText(forTraitCollection traitCollection: UITraitCollection) {

        // Update the font, then the attributed string. If the font doesn't keep in sync when
        // not using attributedText, weird things happen so update it first.
        // See UIKitTests.testLabelFontPropertyBehavior for interesting behavior.

        if let bonMotStyle = bonMotStyle {
            let attributes = NSAttributedString.adapt(attributes: bonMotStyle.attributes, to: traitCollection)
            font = attributes[NSFontAttributeName] as? BONFont
        }
        if let attributedText = attributedText {
            self.attributedText = attributedText.adapted(to: traitCollection)
        }
    }

}

extension UITextView: AdaptableTextContainer {

    /// Adapt `attributedText` and `typingAttributes` to the specified trait collection.
    ///
    /// - parameter traitCollection: The updated trait collection
    @objc(bon_updateTextForTraitCollection:)
    public func adaptText(forTraitCollection traitCollection: UITraitCollection) {
        if let attributedText = attributedText {
            self.attributedText = attributedText.adapted(to: traitCollection)
        }
        self.typingAttributes = NSAttributedString.adapt(attributes: typingAttributes, to: traitCollection)
    }

}

extension UITextField: AdaptableTextContainer {

    /// Adapt `attributedText`, `attributedPlaceholder`, and
    /// `defaultTextAttributes` to the specified trait collection.
    ///
    /// - note: Do not modify `typingAttributes`, as they are relevant only 
    ///         while the text field has first responder status, and they are
    ///         reset as new text is entered.
    ///
    /// - parameter traitCollection: The new trait collection.
    @objc(bon_updateTextForTraitCollection:)
    public func adaptText(forTraitCollection traitCollection: UITraitCollection) {
        if let attributedText = attributedText?.adapted(to: traitCollection) {
            if attributedText.length > 0 {
                font = attributedText.attribute(NSFontAttributeName, at: 0, effectiveRange: nil) as? UIFont
            }
            self.attributedText = attributedText
        }
        if let attributedPlaceholder = attributedPlaceholder {
            self.attributedPlaceholder = attributedPlaceholder.adapted(to: traitCollection)
        }
        defaultTextAttributes = NSAttributedString.adapt(attributes: defaultTextAttributes, to: traitCollection)
        // Fix an issue where shrinking or growing text would stay the same width, but add whitespace.
        setNeedsDisplay()
    }

}

/*
extension UIButton: AdaptableTextContainer {

    /// Adapt `attributedTitle`, for all control states, to the specified trait collection.
    ///
    /// - parameter traitCollection: The new trait collection.
    @objc(bon_updateTextForTraitCollection:)
    public func adaptText(forTraitCollection traitCollection: UITraitCollection) {
        for state in UIControlState.commonStates {
            #if swift(>=3.0)
                let attributedText = attributedTitle(for: state)?.adapted(to: traitCollection)
                setAttributedTitle(attributedText, for: state)
            #else
                let attributedText = attributedTitleForState(state)?.adapted(to: traitCollection)
                setAttributedTitle(attributedText, forState: state)
            #endif
        }
    }

}
*/
 
 
extension UISegmentedControl: AdaptableTextContainer {

    // `UISegmentedControl` has terrible generics ([NSObject: AnyObject]?) on
    /// `titleTextAttributes`, so use a helper in Swift 3.0.
    #if swift(>=3.0)
    @nonobjc final func bon_titleTextAttributes(for state: UIControlState) -> StyleAttributes {
        let attributes = titleTextAttributes(for: state) ?? [:]
        var result: StyleAttributes = [:]
        for value in attributes {
            guard let string = value.key as? String else {
                fatalError("Can not convert key \(value.key) to String")
            }
            result[string] = value
        }
        return result
    }
    #endif

    /// Adapt `attributedTitle`, for all control states, to the specified trait collection.
    ///
    /// - parameter traitCollection: The new trait collection.
    @objc(bon_updateTextForTraitCollection:)
    public func adaptText(forTraitCollection traitCollection: UITraitCollection) {
        for state in UIControlState.commonStates {
            #if swift(>=3.0)
                let attributes = bon_titleTextAttributes(for: state)
                let newAttributes = NSAttributedString.adapt(attributes: attributes, to: traitCollection)
                setTitleTextAttributes(newAttributes, for: state)
            #else
                if let attributes = titleTextAttributesForState(state) as? StyleAttributes {
                    let newAttributes = NSAttributedString.adapt(attributes: attributes, to: traitCollection)
                    setTitleTextAttributes(newAttributes, forState: state)
                }
            #endif
        }
    }

}

extension UINavigationBar: AdaptableTextContainer {

    /// Adapt `titleTextAttributes` to the specified trait collection.
    ///
    /// - note: This does not update the bar button items. These should be
    ///         updated by the containing view controller.
    ///
    /// - parameter traitCollection: The new trait collection.
    @objc(bon_updateTextForTraitCollection:)
    public func adaptText(forTraitCollection traitCollection: UITraitCollection) {
        if let titleTextAttributes = titleTextAttributes {
            self.titleTextAttributes = NSAttributedString.adapt(attributes: titleTextAttributes, to: traitCollection)
        }
    }

}

#if os(tvOS)
#else
extension UIToolbar: AdaptableTextContainer {

    /// Adapt all bar items's attributed text to the specified trait collection.
    ///
    /// - note: This will update only bar items that are contained on the screen
    ///         at the time that it is called.
    ///
    /// - parameter traitCollection: The updated trait collection
    @objc(bon_updateTextForTraitCollection:)
    public func adaptText(forTraitCollection traitCollection: UITraitCollection) {
        for item in items ?? [] {
            item.adaptText(forTraitCollection: traitCollection)
        }
    }

}
#endif

extension UIViewController: AdaptableTextContainer {

    /// Adapt the attributed text of teh bar items in the navigation item or in
    /// the toolbar to the specified trait collection.
    ///
    /// - parameter traitCollection: The new trait collection.
    @objc(bon_updateTextForTraitCollection:)
    public func adaptText(forTraitCollection traitCollection: UITraitCollection) {
        for item in navigationItem.allBarItems {
            item.adaptText(forTraitCollection: traitCollection)
        }
        #if os(tvOS)
        #else
            for item in toolbarItems ?? [] {
                item.adaptText(forTraitCollection: traitCollection)
            }
            if let backBarButtonItem = navigationItem.backBarButtonItem {
                backBarButtonItem.adaptText(forTraitCollection: traitCollection)
            }
        #endif
    }

}

extension UIBarItem: AdaptableTextContainer {

    /// Adapt `titleTextAttributes` to the specified trait collection.
    ///
    /// - note: This extension does not conform to `AdaptableTextContainer`
    /// because `UIBarIterm` is not a view or view controller.
    /// - parameter traitCollection: the new trait collection.
    @objc(bon_updateTextForTraitCollection:)
    public func adaptText(forTraitCollection traitCollection: UITraitCollection) {
        for state in UIControlState.commonStates {
            #if swift(>=3.0)
                let attributes = titleTextAttributes(for: state) ?? [:]
                let newAttributes = NSAttributedString.adapt(attributes: attributes, to: traitCollection)
                setTitleTextAttributes(newAttributes, for: state)
            #else
                let attributes = titleTextAttributesForState(state) ?? [:]
                let newAttributes = NSAttributedString.adapt(attributes: attributes, to: traitCollection)
                setTitleTextAttributes(newAttributes, forState: state)
            #endif
        }
    }

}

extension UIControlState {

    /// The most common states that are used in apps. Using this defined set of
    /// attributes is far simpler than trying to build a system that will
    /// iterate through only the permutations that are currently configured. If
    /// you use a valid `UIControlState` in your app that is not represented
    /// here, please open a pull request to add it.
    @nonobjc static var commonStates: [UIControlState] {
        #if swift(>=3.0)
            return [.normal, .highlighted, .disabled, .selected, [.highlighted, .selected]]
        #else
            return [.Normal, .Highlighted, .Disabled, .Selected, [.Highlighted, .Selected]]
        #endif
    }

}

extension UINavigationItem {

    /// Convenience getter comprising `leftBarButtonItems` and `rightBarButtonItems`.
    final var allBarItems: [UIBarButtonItem] {
        var allBarItems = leftBarButtonItems ?? []
        allBarItems.append(contentsOf: rightBarButtonItems ?? [])
        return allBarItems
    }

}
