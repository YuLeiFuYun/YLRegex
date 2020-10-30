//
//  MatchedResult.swift
//  MDParse-Test
//
//  Created by 玉垒浮云 on 2020/10/30.
//

import Foundation.NSTextCheckingResult

public struct MatchedResult {
    private var _result: _MatchResult
    
    init(_ string: String, _ result: NSTextCheckingResult) {
        self._result = _MatchResult(string, result)
    }
}

extension MatchedResult {
    public var matchedString: String {
        _result.matchedString
    }
    
    public var captures: [String?] {
        _result.captures
    }
    
    public var range: Range<String.Index> {
        _result.range
    }
    
    public var captureRanges: [Range<String.Index>?] {
        _result.captureRanges
    }
}

fileprivate final class _MatchResult {
    let string: String
    let result: NSTextCheckingResult
    
    init(_ string: String, _ result: NSTextCheckingResult) {
        self.string = string
        self.result = result
    }
    
    lazy var range: Range<String.Index> = {
        Range(result.range, in: string)!
    }()
    
    lazy var captures: [String?] = {
        captureRanges.map { range in
            range.map { String(string[$0]) }
        }
    }()
    
    lazy var captureRanges: [Range<String.Index>?] = {
        var ranges: [Range<String.Index>?] = []
        if result.numberOfRanges > 1 {
            for i in 1..<result.numberOfRanges {
                ranges.append(Range(result.range(at: i), in: string))
            }
        }
        
        return ranges
    }()
    
    lazy var matchedString: String = {
        String(string[Range(result.range, in: string)!])
    }()
}

