import UIKit

/// 화면 왼쪽 가장자리에서 오른쪽으로 스와이프하면 뒤로 가는 제스처를
/// 앱 전체에서 유지한다.
///
/// SwiftUI NavigationStack은 내부적으로 UINavigationController를 쓰는데,
/// 네비게이션 바를 숨기거나(라이브러리 홈) back 버튼을 커스텀하면
/// (에디터의 취소/저장) 기본 interactive pop 제스처가 비활성화된다.
/// delegate를 넘겨받아 "쌓인 화면이 있으면 항상 스와이프 가능"으로 되돌린다.
///
/// 에디터처럼 이탈 확인이 필요한 화면은 onDisappear에서 draft를 저장해
/// 스와이프로 나가도 입력을 잃지 않는다.
extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // 루트 화면에서는 뒤로 갈 곳이 없으므로 시작하지 않는다.
        viewControllers.count > 1
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // 가로 스크롤 뷰(사진 스트립 등)와 동시 인식은 막아 오동작을 줄인다.
        false
    }
}
