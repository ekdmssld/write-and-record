import Foundation

enum NicknameCheckResult: Equatable {
    case available
    case invalid(String)
    case taken
}

/// 닉네임 중복 확인. 지금은 로컬 규칙 검사만 하고,
/// 서버/동기화가 생기면 이 protocol 구현체만 교체한다.
protocol NicknameChecking {
    func check(_ nickname: String) async -> NicknameCheckResult
}

struct LocalNicknameChecker: NicknameChecking {
    /// 로컬 단일 사용자 앱이라 실제 중복 대상이 없으므로
    /// 형식 검증 + 예약어 검사만 수행한다.
    private static let reservedNames = ["admin", "administrator", "system", "운영자", "관리자"]

    func check(_ nickname: String) async -> NicknameCheckResult {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Validation.isValidNickname(trimmed) else {
            return .invalid("닉네임은 공백 제외 1~20자로 입력해 주세요.")
        }
        guard !Self.reservedNames.contains(trimmed.lowercased()) else {
            return .taken
        }
        return .available
    }
}
