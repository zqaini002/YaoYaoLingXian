package com.dreamplanner.service;

import com.dreamplanner.dto.LoginDTO;
import com.dreamplanner.dto.RegisterDTO;
import com.dreamplanner.entity.User;

/**
 * 认证服务接口
 */
public interface AuthService {

    /**
     * 用户登录
     * @param loginDTO 登录信息
     * @return 登录成功的用户信息
     */
    User login(LoginDTO loginDTO);

    /**
     * 用户注册
     * @param registerDTO 注册信息
     * @return 注册成功的用户信息
     */
    User register(RegisterDTO registerDTO);

    /**
     * 检查用户名是否可用
     * @param username 用户名
     * @return 如果用户名可用返回true，否则返回false
     */
    boolean isUsernameAvailable(String username);
} 