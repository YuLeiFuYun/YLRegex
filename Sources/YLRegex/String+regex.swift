//
//  String+regex.swift
//  MDParse-Test
//
//  Created by 玉垒浮云 on 2020/10/30.
//

import Foundation

extension String {
    public func firstMatch(
        pattern: String,
        options: NSRegularExpression.Options = .dotMatchesLineSeparators
    ) -> MatchedResult? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            guard
                let match = regex.firstMatch(
                    in: self, options: [],
                    range: NSRange(location: 0, length: utf16.count)
                )
            else { return nil }
            
            return MatchedResult(self, match)
        } catch {
            fatalError("正则表达式有误，请更正后再试！")
        }
    }
    
    public func allMatches(
        pattern: String,
        options: NSRegularExpression.Options = .dotMatchesLineSeparators
    ) -> [MatchedResult] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: utf16.count))
            
            var results: [MatchedResult] = []
            for match in matches {
                results.append(MatchedResult(self, match))
            }
            
            return results
        } catch {
            fatalError("正则表达式有误，请更正后再试！")
        }
    }
    
    public func match(
        pattern: String,
        options: NSRegularExpression.Options = .dotMatchesLineSeparators
    ) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: utf16.count))
            
            return matches.count != 0
        } catch {
            fatalError("正则表达式有误，请更正后再试！")
        }
    }
    
    /// 正则分割字符串
    public func split(
        usingRegex pattern: String,
        options: NSRegularExpression.Options = .dotMatchesLineSeparators
    ) -> [SplitedResult] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let matches = regex.matches(
                in: self, options: [],
                range: NSRange(location: 0, length: utf16.count)
            )
            
            var currentIndex = startIndex
            var range: Range<String.Index>
            var captures: [String?] = []
            var results: [SplitedResult] = []
            for match in matches {
                range = Range(match.range, in: self)!
                if range.lowerBound > currentIndex {
                    results.append(
                        SplitedResult(
                            isMatched: false,
                            text: String(self[currentIndex..<range.lowerBound]),
                            captures: []
                        )
                    )
                }
                
                if match.numberOfRanges > 1 {
                    for i in 1..<match.numberOfRanges {
                        if let _range = Range(match.range(at: i), in: self) {
                            captures.append(String(self[_range]))
                        } else {
                            captures.append(nil)
                        }
                    }
                }
                
                results.append(SplitedResult(isMatched: true, text: String(self[range]), captures: captures))
                currentIndex = range.upperBound
                captures.removeAll()
            }
            
            if endIndex > currentIndex {
                results.append(
                    SplitedResult(
                        isMatched: false,
                        text: String(self[currentIndex..<endIndex]),
                        captures: []
                    )
                )
            }
            
            return results
        } catch {
            fatalError("正则表达式有误，请更正后再试！")
        }
    }
    
    public func replacingAll(
        matching pattern: String,
        with template: String,
        options: NSRegularExpression.Options = .dotMatchesLineSeparators
    ) -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            return regex.stringByReplacingMatches(
                in: self, options: [],
                range: NSRange(location: 0, length: utf16.count),
                withTemplate: template
            )
        } catch {
            fatalError("正则表达式有误，请更正后再试！")
        }
    }
    
    public mutating func replaceAll(
        matching pattern: String,
        with template: String,
        options: NSRegularExpression.Options = .dotMatchesLineSeparators
    ) {
        self = replacingAll(matching: pattern, with: template, options: options)
    }
    
    public func replacingAll(matching pattern: String, transform: (SplitedResult) -> String) -> String {
        split(usingRegex: pattern)
            .map { result -> String in
                if result.isMatched {
                    return transform(result)
                } else {
                    return result.text
                }
            }
            .reduce("", +)
    }
    
    public mutating func replaceAll(matching pattern: String, transform: (SplitedResult) -> String) {
        self = replacingAll(matching: pattern, transform: transform)
    }
    
    /// 特殊字段转义
    /// &amp; -> &
    /// &quot; -> "
    /// &lt; -> <
    /// &gt; -> >
    public mutating func escapeSpecialFields() {
        self = escapingSpecialFields()
    }
    
    /// 特殊字段转义
    /// &amp; -> &
    /// &quot; -> "
    /// &lt; -> <
    /// &gt; -> >
    public func escapingSpecialFields() -> String {
        var dict: [String: String] = ["&amp;": "&"]
        dict["&quot;"] = #"\""#
        dict["&lt;"] = "<"
        dict["&gt;"] = ">"
        
        var result = self
        result.replaceFields(with: dict)
        return result
    }
    
    /// 根据字典替换字段
    public mutating func replaceFields(with dict: [String: String]) {
        self = replacingFields(with: dict)
    }
    
    /// 根据字典替换字段
    public func replacingFields(with dict: [String: String]) -> String {
        var result = self
        dict.keys.forEach { (filed: String) in
            result = result.replacingOccurrences(of: filed, with: dict[filed]!)
        }
        return result
    }
    
    /// 将邮箱保护字段替换为解码后的字段
    public mutating func decodeProtectedFields() {
        self = decodingProtectedFields()
    }
    
    /// 将邮箱保护字段替换为解码后的字段
    public func decodingProtectedFields() -> String {
        var result = self
        let pattern = #"<a href.*?data-cfemail="([0-9a-f]+).*?</a>"#
        let matches = allMatches(pattern: pattern)
        for match in matches {
            let email = match.captures[0]!.decodeCFMail()
            result.replaceAll(matching: pattern, with: email)
        }
        
        return result
    }
    
    /// 解密 Cloudflare 邮箱保护
    // 算法来自 https://blog.shiniv.com/2016/09/decode-encode-cloudflare-address-obfuscation/
    public func decodeCFMail() -> String {
        var result = ""
        var start = self.startIndex
        var end = self.index(startIndex, offsetBy: 2)
        let rhs = String(self[..<end]).hexdec()
        for _ in stride(from: 2, to: count, by: 2) {
            start = end
            end = self.index(start, offsetBy: 2)
            let lhs = String(self[start..<end]).hexdec()
            var value = lhs^rhs
            result += NSString(
                bytes: &value, length: 2,
                encoding: String.Encoding.utf8.rawValue
            )! as String
        }
        
        return result
    }
    
    /// 十六进制转换为十进制
    public func hexdec() -> Int {
        if let value = Int(self, radix: 16) {
            return value
        } else {
            fatalError("格式有误！")
        }
    }
}
