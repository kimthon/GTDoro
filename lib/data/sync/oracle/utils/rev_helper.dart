import 'dart:developer' as dev;
import 'package:flutter/material.dart';

/// rev 필드 관리 유틸리티
/// rev 오버플로우 및 형식 불일치 처리
class RevHelper {
  // rev 최대값 (오버플로우 방지)
  // 타임스탬프 기반: millisecondsSinceEpoch는 13자리 (약 10^12)
  // 숫자-해시 형태: 숫자 부분이 매우 커질 수 있음
  // 안전한 최대값 설정 (약 10^15, 충분히 큰 값이면서 오버플로우 방지)
  static const int maxRevNumber = 9007199254740991; // JavaScript Number.MAX_SAFE_INTEGER와 동일
  static const int overflowThreshold = 9000000000000000; // 오버플로우 임계값
  
  /// rev 문자열 파싱 (숫자-해시 형태 또는 숫자만)
  /// 반환: {number: int, hash: String?}
  static Map<String, dynamic>? parseRev(String? rev) {
    if (rev == null || rev.isEmpty) {
      return null;
    }
    
    // 숫자-해시 형태 확인 (예: "83-bfe637daf1153252ac3633f1b513b7e0")
    final parts = rev.split('-');
    if (parts.length >= 2) {
      // 첫 번째 부분이 숫자인지 확인
      final numberStr = parts[0];
      final number = int.tryParse(numberStr);
      
      if (number != null) {
        // 오버플로우 체크
        if (number > overflowThreshold) {
          debugPrint('RevHelper: ⚠️ Rev number ($number) approaching overflow threshold ($overflowThreshold)');
          dev.log('RevHelper: Rev overflow warning - number: $number, threshold: $overflowThreshold');
        }
        
        return {
          'number': number,
          'hash': parts.sublist(1).join('-'), // 해시 부분 (하이픈 포함 가능)
          'original': rev,
        };
      }
    }
    
    // 숫자만 있는 형태 (타임스탬프 등)
    final number = int.tryParse(rev);
    if (number != null) {
      // 오버플로우 체크
      if (number > overflowThreshold) {
        debugPrint('RevHelper: ⚠️ Rev number ($number) approaching overflow threshold ($overflowThreshold)');
        dev.log('RevHelper: Rev overflow warning - number: $number, threshold: $overflowThreshold');
      }
      
      return {
        'number': number,
        'hash': null,
        'original': rev,
      };
    }
    
    // 파싱 실패 (잘못된 형식)
    debugPrint('RevHelper: ⚠️ Failed to parse rev: $rev');
    dev.log('RevHelper: Failed to parse rev: $rev');
    return null;
  }
  
  /// rev 숫자 부분 추출 (비교용)
  /// 오버플로우 시 안전한 처리
  static int? extractRevNumber(String? rev) {
    final parsed = parseRev(rev);
    if (parsed == null) return null;
    
    final number = parsed['number'] as int;
    
    // 오버플로우 체크
    if (number > maxRevNumber) {
      debugPrint('RevHelper: ⚠️ Rev number ($number) exceeds max safe value ($maxRevNumber), resetting to threshold');
      dev.log('RevHelper: Rev overflow detected - resetting to threshold');
      return overflowThreshold;
    }
    
    return number;
  }
  
  /// rev 비교 (숫자 기반, 오버플로우 안전)
  /// 반환: -1 (local < remote), 0 (equal), 1 (local > remote)
  /// 
  /// 참고: 매우 작은 차이(1-5)는 동기화 지연으로 인한 것으로 간주하여
  /// 동기화된 것으로 처리합니다 (uploadSingleItem 후 서버 rev 업데이트 지연 대응)
  static int compareRev(String? localRev, String? remoteRev) {
    final localNum = extractRevNumber(localRev);
    final remoteNum = extractRevNumber(remoteRev);
    
    if (localNum == null && remoteNum == null) {
      return 0; // 둘 다 null이면 같음
    }
    if (localNum == null) {
      return -1; // 로컬이 null이면 원격이 더 최신
    }
    if (remoteNum == null) {
      return 1; // 원격이 null이면 로컬이 더 최신
    }
    
    // 오버플로우 처리: 큰 차이는 감지하되, 실제 비교는 안전하게
    if (localNum > overflowThreshold && remoteNum > overflowThreshold) {
      // 둘 다 임계값을 초과한 경우, 해시 비교 또는 리셋 필요
      debugPrint('RevHelper: ⚠️ Both revs exceed threshold, comparing strings directly');
      final localStr = localRev ?? '';
      final remoteStr = remoteRev ?? '';
      return localStr.compareTo(remoteStr); // 문자열 비교로 대체
    }
    
    // 정상적인 숫자 비교
    final diff = localNum - remoteNum;
    
    // 매우 작은 차이(1-5)는 동기화 지연으로 인한 것으로 간주하여 동기화된 것으로 처리
    // uploadSingleItem 후 서버 rev 업데이트 지연 대응
    if (diff.abs() <= 5) {
      // 해시가 있으면 해시 비교, 없으면 동기화된 것으로 간주
      final localParsed = parseRev(localRev);
      final remoteParsed = parseRev(remoteRev);
      final localHash = localParsed?['hash'] as String?;
      final remoteHash = remoteParsed?['hash'] as String?;
      
      if (localHash != null && remoteHash != null) {
        // 해시가 있으면 해시 비교
        final hashComparison = localHash.compareTo(remoteHash);
        if (hashComparison != 0) {
          // 해시가 다르면 실제 차이 반환
          return diff > 0 ? 1 : -1;
        }
      }
      
      // 해시가 없거나 같으면 동기화된 것으로 간주
      return 0;
    }
    
    // 차이가 5보다 크면 실제 차이 반환
    if (diff < 0) {
      return -1;
    } else if (diff > 0) {
      return 1;
    } else {
      // 숫자가 같으면 해시 비교 (있는 경우)
      final localParsed = parseRev(localRev);
      final remoteParsed = parseRev(remoteRev);
      final localHash = localParsed?['hash'] as String?;
      final remoteHash = remoteParsed?['hash'] as String?;
      
      if (localHash != null && remoteHash != null) {
        return localHash.compareTo(remoteHash);
      }
      
      return 0; // 숫자가 같고 해시가 없으면 같음
    }
  }
  
  /// 새로운 rev 생성 (오버플로우 방지)
  /// 로컬 문서 수정 시 사용
  static String generateNewRev({String? previousRev}) {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    
    // 이전 rev가 있으면 숫자 증가, 없으면 타임스탬프 사용
    if (previousRev != null && previousRev.isNotEmpty) {
      final parsed = parseRev(previousRev);
      if (parsed != null) {
        final previousNum = parsed['number'] as int;
        final previousHash = parsed['hash'] as String?;
        
        // 오버플로우 체크
        if (previousNum >= maxRevNumber) {
          // 오버플로우 발생 시 타임스탬프로 리셋 (더 안전)
          debugPrint('RevHelper: ⚠️ Rev overflow detected, resetting to timestamp');
          dev.log('RevHelper: Rev overflow - previous: $previousNum, resetting to: $timestamp');
          return timestamp.toString();
        }
        
        // 숫자 증가 (해시 유지)
        final newNum = previousNum + 1;
        if (previousHash != null) {
          return '$newNum-$previousHash';
        }
        return newNum.toString();
      }
    }
    
    // 이전 rev가 없거나 파싱 실패 시 타임스탬프 사용
    return timestamp.toString();
  }
  
  /// rev가 오버플로우 위험인지 확인
  static bool isOverflowRisk(String? rev) {
    final parsed = parseRev(rev);
    if (parsed == null) return false;
    
    final number = parsed['number'] as int;
    return number > overflowThreshold;
  }
  
  /// rev 리셋 (오버플로우 발생 시)
  static String resetRev() {
    final now = DateTime.now();
    return now.millisecondsSinceEpoch.toString();
  }
}
