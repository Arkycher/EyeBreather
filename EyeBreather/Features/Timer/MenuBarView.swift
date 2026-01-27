import SwiftUI

/// 菜单栏弹出视图
struct MenuBarView: View {
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "eye")
                    .font(.title2)
                Text("EyeBreather")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            Divider()
            
            // 占位内容（后续实现）
            VStack(spacing: 8) {
                Text("下次休息：--:-- (-- 分钟后)")
                    .font(.subheadline)
                
                ProgressView(value: 0.0)
                    .progressViewStyle(.linear)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("📊 今日统计")
                        .font(.subheadline.bold())
                    Text("使用时长：--")
                        .font(.caption)
                    Text("休息次数：--/--")
                        .font(.caption)
                    Text("完成率：--%")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            
            Divider()
            
            // 操作按钮
            HStack {
                Button("⏸️ 暂停") {
                    // TODO: 暂停计时
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Button("▶️ 立即休息") {
                    // TODO: 开始休息
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)
            
            Divider()
            
            // 底部按钮
            HStack {
                Button("设置...") {
                    // TODO: 打开设置窗口
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .frame(width: 280, height: 320)
    }
}

#Preview {
    MenuBarView()
}
