aboutToAppear() {
    // 初始化用户会话
    UserSession.getInstance().init().catch((error: Error) => {
        console.error('初始化用户会话失败:', error);
    });
} 