package com.dreamplanner.service.impl;

import com.dreamplanner.dto.LoginDTO;
import com.dreamplanner.dto.RegisterDTO;
import com.dreamplanner.entity.User;
import com.dreamplanner.exception.BusinessException;
import com.dreamplanner.repository.UserRepository;
import com.dreamplanner.service.AuthService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Optional;

/**
 * 认证服务实现类
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public User login(LoginDTO loginDTO) {
        log.info("用户登录: {}", loginDTO.getUsername());
        
        // 查找用户
        User user = userRepository.findByUsername(loginDTO.getUsername())
                .orElseThrow(() -> new BusinessException("用户名或密码错误", HttpStatus.UNAUTHORIZED));
        
        // 验证密码
        if (!passwordEncoder.matches(loginDTO.getPassword(), user.getPassword())) {
            log.warn("密码错误: {}", loginDTO.getUsername());
            throw new BusinessException("用户名或密码错误", HttpStatus.UNAUTHORIZED);
        }
        
        // 检查用户状态
        if (user.getStatus() != null && user.getStatus() != 1) {
            log.warn("用户已被禁用: {}", loginDTO.getUsername());
            throw new BusinessException("账号已被禁用，请联系管理员", HttpStatus.FORBIDDEN);
        }
        
        log.info("用户登录成功: {}", loginDTO.getUsername());
        return user;
    }

    @Override
    @Transactional
    public User register(RegisterDTO registerDTO) {
        log.info("用户注册: {}", registerDTO.getUsername());
        
        // 检查用户名是否已存在
        if (!isUsernameAvailable(registerDTO.getUsername())) {
            log.warn("用户名已存在: {}", registerDTO.getUsername());
            throw new BusinessException("用户名已被使用");
        }
        
        // 检查邮箱是否已存在
        if (registerDTO.getEmail() != null && !registerDTO.getEmail().isEmpty()) {
            Optional<User> userOptional = userRepository.findByEmail(registerDTO.getEmail());
            if (userOptional.isPresent()) {
                log.warn("邮箱已存在: {}", registerDTO.getEmail());
                throw new BusinessException("邮箱已被使用");
            }
        }
        
        // 检查手机号是否已存在
        if (registerDTO.getPhone() != null && !registerDTO.getPhone().isEmpty()) {
            Optional<User> userOptional = userRepository.findByPhone(registerDTO.getPhone());
            if (userOptional.isPresent()) {
                log.warn("手机号已存在: {}", registerDTO.getPhone());
                throw new BusinessException("手机号已被使用");
            }
        }
        
        // 创建新用户
        User user = new User();
        user.setUsername(registerDTO.getUsername());
        user.setPassword(passwordEncoder.encode(registerDTO.getPassword()));
        user.setNickname(registerDTO.getNickname());
        user.setEmail(registerDTO.getEmail());
        user.setPhone(registerDTO.getPhone());
        user.setStatus(1); // 正常状态
        user.setGender(0); // 默认未知
        user.setAvatar("https://api.dicebear.com/7.x/avataaars/svg?seed=" + registerDTO.getUsername()); // 默认头像
        user.setCreateTime(LocalDateTime.now());
        user.setUpdateTime(LocalDateTime.now());
        
        userRepository.save(user);
        log.info("用户注册成功: {}", registerDTO.getUsername());
        
        return user;
    }

    @Override
    public boolean isUsernameAvailable(String username) {
        return !userRepository.existsByUsername(username);
    }
} 