package com.dreamplanner.controller;

import com.dreamplanner.common.ApiResponse;
import com.dreamplanner.dto.LoginDTO;
import com.dreamplanner.dto.RegisterDTO;
import com.dreamplanner.dto.UserDTO;
import com.dreamplanner.entity.User;
import com.dreamplanner.service.AuthService;
import com.dreamplanner.util.JwtUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * 认证控制器
 */
@Slf4j
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@Tag(name = "认证管理", description = "用户登录、注册和认证相关接口")
public class AuthController {

    private final AuthService authService;
    private final JwtUtil jwtUtil;

    @PostMapping("/login")
    @Operation(summary = "用户登录", description = "用户登录接口，返回用户信息和token")
    public ApiResponse login(@Valid @RequestBody LoginDTO loginDTO) {
        log.info("用户登录: {}", loginDTO.getUsername());
        User user = authService.login(loginDTO);
        
        // 生成JWT Token
        String token = jwtUtil.generateToken(user.getId(), user.getUsername());
        
        // 转换为DTO并添加token
        UserDTO userDTO = UserDTO.fromUser(user);
        Map<String, Object> result = new HashMap<>();
        result.put("user", userDTO);
        result.put("token", token);
        
        return ApiResponse.success("登录成功", result);
    }

    @PostMapping("/register")
    @Operation(summary = "用户注册", description = "用户注册接口，返回用户信息和token")
    public ApiResponse register(@Valid @RequestBody RegisterDTO registerDTO) {
        log.info("用户注册: {}", registerDTO.getUsername());
        User user = authService.register(registerDTO);
        
        // 生成JWT Token
        String token = jwtUtil.generateToken(user.getId(), user.getUsername());
        
        // 转换为DTO并添加token
        UserDTO userDTO = UserDTO.fromUser(user);
        Map<String, Object> result = new HashMap<>();
        result.put("user", userDTO);
        result.put("token", token);
        
        return ApiResponse.success("注册成功", result);
    }

    @GetMapping("/check-username")
    @Operation(summary = "检查用户名是否可用", description = "检查用户名是否已被注册")
    public ApiResponse checkUsername(@RequestParam String username) {
        log.info("检查用户名: {}", username);
        boolean isAvailable = authService.isUsernameAvailable(username);
        return ApiResponse.success("查询成功", isAvailable);
    }
    
    @PostMapping("/logout")
    @Operation(summary = "用户登出", description = "用户登出接口，前端清除token即可")
    public ApiResponse logout() {
        log.info("用户登出");
        // JWT认证模式下，服务端无需特殊处理，只需要前端清除token
        // 如果需要记录用户登出行为或使token失效，可在此处添加相关逻辑
        return ApiResponse.success("登出成功", new HashMap<>());
    }
} 