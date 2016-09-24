//
//  AdaptiveStyleTransformation.swift
//
//  Created by Brian King on 9/20/16.
//
//

import UIKit

/// This protocol defines a style transformation that is dependent on a UITraitCollection.
/// An adaptive transformation is embeded in the StyleAttributes so that any NSAttributedString
/// can be updated to a new trait collection using `attributedString.adapt(to: traitCollection)`.
///
/// Since NSAttributedString includes NSCoding support, AdaptiveStyleTransformation is embedded
/// in the StyleAttributes via a simple dictionary encoding strategy. NSCoding was avoided so
/// value types can be used.
protocol AdaptiveStyleTransformation {

    /// Change any of theAttributes as desired to the specified traitCollection and return a new StyleAttributes dictionary.
    ///
    /// - parameter theAttributes: The input attributes
    /// - parameter to: The trait collection to adapt to
    func adapt(attributes theAttributes: StyleAttributes, to traitCollection: UITraitCollection) -> StyleAttributes?

    /// Return a plist compatible dictionary of any state that's needed to persist the adaption
    var representation: StyleAttributes { get }

    /// This factory method is used to take the adaptations dictionary and create an array of AdaptiveStyleTransformation.
    /// To register a new adaptive transformation, add the type to AdaptiveAttributeHelpers.adaptiveTransformationTypes.
    static func from(representation dictionary: StyleAttributes) -> AdaptiveStyleTransformation?

}