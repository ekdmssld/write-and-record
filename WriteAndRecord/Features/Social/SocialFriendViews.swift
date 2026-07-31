import SwiftUI

/// 친구들 탭: 친구 피드 + 찾기/초대하기 (docs/11 4장).
struct SocialFriendsTabView: View {
    var onGoToAdd: () -> Void

    @EnvironmentObject private var socialRepository: SocialRepository
    @EnvironmentObject private var appState: AppState

    @State private var showInviteSheet = false
    @State private var toastMessage: String?

    var body: some View {
        let friends = socialRepository.friends()
        let feed = socialRepository.friendFeed()
        let received = socialRepository.receivedRequests

        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
                Text(friends.isEmpty ? "함께 기록을 나눌 친구를 찾아볼까요?" : "친구들이 공유한 기록이에요.")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.horizontal, AppLayout.horizontalPadding)
                    .padding(.top, AppLayout.smallGap)

                // 필수 quick actions: 찾기 / 초대하기
                HStack(spacing: AppLayout.smallGap) {
                    quickAction(icon: "magnifyingglass", label: "찾기", helper: "닉네임으로 친구 찾기") {
                        onGoToAdd()
                    }
                    quickAction(icon: "paperplane", label: "초대하기", helper: "링크로 친구 초대") {
                        showInviteSheet = true
                    }
                }
                .padding(.horizontal, AppLayout.horizontalPadding)

                if !received.isEmpty {
                    Button {
                        onGoToAdd()
                    } label: {
                        HStack {
                            Text("받은 친구 요청 \(received.count)개")
                                .font(AppTypography.callout)
                                .foregroundStyle(AppColors.text)
                            Spacer()
                            Text("확인하기")
                                .font(AppTypography.callout)
                                .foregroundStyle(AppColors.primary)
                        }
                        .padding(AppLayout.mediumGap)
                        .background(AppColors.primary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                    }
                    .padding(.horizontal, AppLayout.horizontalPadding)
                }

                if !friends.isEmpty {
                    Text("내 친구")
                        .font(AppTypography.headline)
                        .padding(.horizontal, AppLayout.horizontalPadding)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppLayout.mediumGap) {
                            ForEach(friends) { friend in
                                NavigationLink(value: friend) {
                                    VStack(spacing: 4) {
                                        ZStack {
                                            Circle().fill(AppColors.primary.opacity(0.12))
                                            Image(systemName: "person.fill")
                                                .foregroundStyle(AppColors.primary)
                                        }
                                        .frame(width: 48, height: 48)
                                        Text(friend.nickname)
                                            .font(AppTypography.caption)
                                            .foregroundStyle(AppColors.text)
                                            .lineLimit(1)
                                    }
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        socialRepository.removeFriend(userId: friend.userId)
                                        toastMessage = "친구를 삭제했어요."
                                    } label: {
                                        Label("친구 삭제", systemImage: "person.badge.minus")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppLayout.horizontalPadding)
                    }
                }

                if friends.isEmpty {
                    EmptyStateView(
                        iconName: "person.2",
                        title: "아직 친구가 없어요",
                        subtitle: "닉네임으로 찾거나 초대 링크를 보내보세요.",
                        actionTitle: "친구 찾기"
                    ) {
                        onGoToAdd()
                    }
                } else if feed.isEmpty {
                    EmptyStateView(
                        iconName: "square.and.pencil",
                        title: "친구들이 아직 공유한 기록이 없어요",
                        subtitle: "친구 공개 기록이 생기면 여기에 모여요."
                    )
                } else {
                    VStack(spacing: AppLayout.smallGap) {
                        ForEach(feed) { entry in
                            SocialEntryCard(entry: entry, toastMessage: $toastMessage)
                        }
                    }
                    .padding(.horizontal, AppLayout.horizontalPadding)
                }
            }
            .padding(.bottom, AppLayout.largeGap)
        }
        .toast(message: $toastMessage)
        .sheet(isPresented: $showInviteSheet) {
            InviteShareSheet()
        }
    }

    private func quickAction(icon: String, label: String, helper: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.primary)
                Text(label)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.text)
                Text(helper)
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppLayout.mediumGap)
            .background(AppColors.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        }
        .accessibilityLabel("\(label), \(helper)")
    }
}

/// 초대하기 시트: 초대 링크 표시 + 링크 복사 + 공유(카카오톡/메시지 등 설치된 앱).
struct InviteShareSheet: View {
    @EnvironmentObject private var socialRepository: SocialRepository
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var showSystemShare = false
    @State private var toastMessage: String?

    private var invite: SocialInvite {
        socialRepository.currentInvite()
    }

    private var inviteText: String {
        let message = socialRepository.inviteMessage(
            inviterNickname: appState.profile?.nickname ?? "친구",
            spaceName: appState.profile?.spaceName ?? "내 기록 공간"
        )
        return "\(message)\n\(invite.inviteUrl)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
            Text("초대하기")
                .font(AppTypography.title2)
                .foregroundStyle(AppColors.text)
                .padding(.top, AppLayout.largeGap)

            Text("앱을 쓰지 않는 친구에게도 보낼 수 있어요.")
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textMuted)

            // 초대 링크 미리보기
            HStack(spacing: AppLayout.smallGap) {
                Image(systemName: "link")
                    .foregroundStyle(AppColors.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(invite.inviteUrl)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.text)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text("초대 코드 \(invite.inviteCode)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                }
                Spacer()
            }
            .padding(AppLayout.mediumGap)
            .background(AppColors.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))

            HStack(spacing: AppLayout.mediumGap) {
                SecondaryButton(title: "링크 복사") {
                    UIPasteboard.general.string = inviteText
                    toastMessage = "초대 링크를 복사했어요."
                }
                PrimaryButton(title: "공유하기") {
                    showSystemShare = true
                }
            }

            Text("공유하기를 누르면 카카오톡, 메시지 등 설치된 앱으로 보낼 수 있어요.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)

            Spacer()
        }
        .padding(.horizontal, AppLayout.horizontalPadding)
        .background(AppColors.bg)
        .presentationDetents([.fraction(0.42)])
        .presentationDragIndicator(.visible)
        .toast(message: $toastMessage)
        .sheet(isPresented: $showSystemShare) {
            ShareSheet(items: [inviteText])
        }
    }
}

/// 추가 탭: 검색 / 초대 / 받은·보낸 요청 (docs/11 5장).
struct SocialAddTabView: View {
    @EnvironmentObject private var socialRepository: SocialRepository

    @State private var searchQuery = ""
    @State private var showInviteSheet = false
    @State private var toastMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
                Text("친구를 찾고 초대할 수 있어요.")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.top, AppLayout.smallGap)

                // 검색
                HStack(spacing: AppLayout.smallGap) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppColors.textMuted)
                    TextField("닉네임 또는 공간 이름 검색", text: $searchQuery)
                        .font(AppTypography.body)
                }
                .padding(12)
                .background(AppColors.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))

                searchResults

                // 초대 링크
                VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                    Text("초대 링크 만들기")
                        .font(AppTypography.headline)
                    Text("앱을 쓰지 않는 친구에게도 보낼 수 있어요.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                    SecondaryButton(title: "링크 공유") {
                        showInviteSheet = true
                    }
                }
                .padding(AppLayout.mediumGap)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                        .stroke(AppColors.line, lineWidth: 1)
                )

                requestSections
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.bottom, AppLayout.largeGap)
        }
        .toast(message: $toastMessage)
        .sheet(isPresented: $showInviteSheet) {
            InviteShareSheet()
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            let results = socialRepository.searchUsers(query: query)
            if results.isEmpty {
                VStack(spacing: 4) {
                    Text("찾는 사용자가 없어요")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.text)
                    Text("닉네임을 다시 확인하거나 초대 링크를 보내보세요.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppLayout.mediumGap)
            } else {
                VStack(spacing: AppLayout.smallGap) {
                    ForEach(results) { user in
                        userRow(user)
                    }
                }
            }
        }
    }

    private func userRow(_ user: UserPublicProfile) -> some View {
        let relation = socialRepository.relation(with: user.userId)
        return HStack(spacing: AppLayout.mediumGap) {
            ZStack {
                Circle().fill(AppColors.primary.opacity(0.12))
                Image(systemName: "person.fill")
                    .foregroundStyle(AppColors.primary)
            }
            .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.nickname)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.text)
                Text(user.spaceName)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
            Spacer()
            Button {
                switch relation {
                case .notFriends:
                    socialRepository.sendRequest(to: user.userId)
                    toastMessage = "친구 요청을 보냈어요."
                case .requestReceived:
                    if let request = socialRepository.receivedRequests.first(where: { $0.requesterId == user.userId }) {
                        socialRepository.accept(request)
                        toastMessage = "친구가 됐어요."
                    }
                default:
                    break
                }
            } label: {
                Text(relation == .notFriends ? "추가" : relation.buttonTitle)
                    .font(AppTypography.caption)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(relation == .notFriends || relation == .requestReceived ? AppColors.primary : AppColors.surfaceAlt)
                    .foregroundStyle(relation == .notFriends || relation == .requestReceived ? AppColors.primaryText : AppColors.textMuted)
                    .clipShape(Capsule())
            }
            .disabled(relation == .requestSent || relation == .friends || relation == .blocked)
        }
        .padding(AppLayout.mediumGap)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(AppColors.line, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var requestSections: some View {
        let received = socialRepository.receivedRequests
        let sent = socialRepository.sentRequests

        if !received.isEmpty {
            Text("받은 요청")
                .font(AppTypography.headline)
            VStack(spacing: AppLayout.smallGap) {
                ForEach(received) { request in
                    requestRow(request, incoming: true)
                }
            }
        }
        if !sent.isEmpty {
            Text("보낸 요청")
                .font(AppTypography.headline)
            VStack(spacing: AppLayout.smallGap) {
                ForEach(sent) { request in
                    requestRow(request, incoming: false)
                }
            }
        }
    }

    private func requestRow(_ request: Friendship, incoming: Bool) -> some View {
        let otherId = incoming ? request.requesterId : request.addresseeId
        let user = socialRepository.profile(userId: otherId)
        return HStack(spacing: AppLayout.mediumGap) {
            VStack(alignment: .leading, spacing: 2) {
                Text(user?.nickname ?? "사용자")
                    .font(AppTypography.headline)
                Text(user?.spaceName ?? "")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
            Spacer()
            if incoming {
                Button("수락") {
                    socialRepository.accept(request)
                    toastMessage = "친구가 됐어요."
                }
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.primary)
                Button("거절") {
                    socialRepository.decline(request)
                }
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textMuted)
            } else {
                Text("요청됨")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                Button("취소") {
                    socialRepository.cancelRequest(request)
                }
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.danger)
            }
        }
        .padding(AppLayout.mediumGap)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(AppColors.line, lineWidth: 1)
        )
    }
}
