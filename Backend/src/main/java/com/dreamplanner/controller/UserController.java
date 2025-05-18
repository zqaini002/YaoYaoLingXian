package com.dreamplanner.controller;

import com.dreamplanner.dto.UserDTO;
import com.dreamplanner.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;

/**
 * 用户控制器
 *
 * @author DreamPlanner
 */
@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "用户管理", description = "用户相关接口")
public class UserController {

    private final UserService userService;

    @GetMapping("/{id}")
    @Operation(summary = "获取用户信息", description = "根据用户ID获取用户详细信息")
    public ResponseEntity<UserDTO> getUserById(@PathVariable Long id) {
        log.info("获取用户信息, id: {}", id);
        return ResponseEntity.ok(userService.getUserById(id));
    }

    @GetMapping("/username/{username}")
    @Operation(summary = "根据用户名获取用户信息", description = "根据用户名获取用户详细信息")
    public ResponseEntity<UserDTO> getUserByUsername(@PathVariable String username) {
        log.info("根据用户名获取用户信息, username: {}", username);
        return ResponseEntity.ok(userService.getUserByUsername(username));
    }

    @PostMapping
    @Operation(summary = "创建用户", description = "创建新用户")
    public ResponseEntity<UserDTO> createUser(@Valid @RequestBody UserDTO userDTO) {
        log.info("创建用户, username: {}", userDTO.getUsername());
        return new ResponseEntity<>(userService.createUser(userDTO), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    @Operation(summary = "更新用户信息", description = "更新指定用户的信息")
    @PreAuthorize("hasRole('USER') and (authentication.principal.username == #userDTO.username or hasRole('ADMIN'))")
    public ResponseEntity<UserDTO> updateUser(@PathVariable Long id, @Valid @RequestBody UserDTO userDTO) {
        log.info("更新用户信息, id: {}", id);
        return ResponseEntity.ok(userService.updateUser(id, userDTO));
    }

    @GetMapping
    @Operation(summary = "获取所有用户", description = "分页获取所有用户列表")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Page<UserDTO>> getAllUsers(Pageable pageable) {
        log.info("获取所有用户, page: {}, size: {}", pageable.getPageNumber(), pageable.getPageSize());
        return ResponseEntity.ok(userService.getAllUsers(pageable));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "删除用户", description = "根据ID删除用户")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        log.info("删除用户, id: {}", id);
        userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/check/username/{username}")
    @Operation(summary = "检查用户名是否可用", description = "检查指定的用户名是否已被使用")
    public ResponseEntity<Boolean> isUsernameAvailable(@PathVariable String username) {
        log.info("检查用户名是否可用, username: {}", username);
        return ResponseEntity.ok(userService.isUsernameAvailable(username));
    }

    @GetMapping("/check/email/{email}")
    @Operation(summary = "检查邮箱是否可用", description = "检查指定的邮箱是否已被使用")
    public ResponseEntity<Boolean> isEmailAvailable(@PathVariable String email) {
        log.info("检查邮箱是否可用, email: {}", email);
        return ResponseEntity.ok(userService.isEmailAvailable(email));
    }

    @GetMapping("/check/phone/{phone}")
    @Operation(summary = "检查手机号是否可用", description = "检查指定的手机号是否已被使用")
    public ResponseEntity<Boolean> isPhoneAvailable(@PathVariable String phone) {
        log.info("检查手机号是否可用, phone: {}", phone);
        return ResponseEntity.ok(userService.isPhoneAvailable(phone));
    }

    @PostMapping("/{followerId}/follow/{followingId}")
    @Operation(summary = "关注用户", description = "当前用户关注另一个用户")
    @PreAuthorize("hasRole('USER') and authentication.principal.id == #followerId")
    public ResponseEntity<Void> followUser(@PathVariable Long followerId, @PathVariable Long followingId) {
        log.info("关注用户, followerId: {}, followingId: {}", followerId, followingId);
        userService.followUser(followerId, followingId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{followerId}/unfollow/{followingId}")
    @Operation(summary = "取消关注", description = "当前用户取消关注另一个用户")
    @PreAuthorize("hasRole('USER') and authentication.principal.id == #followerId")
    public ResponseEntity<Void> unfollowUser(@PathVariable Long followerId, @PathVariable Long followingId) {
        log.info("取消关注, followerId: {}, followingId: {}", followerId, followingId);
        userService.unfollowUser(followerId, followingId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/{followerId}/is-following/{followingId}")
    @Operation(summary = "检查是否已关注", description = "检查当前用户是否已关注指定用户")
    public ResponseEntity<Boolean> isFollowing(@PathVariable Long followerId, @PathVariable Long followingId) {
        log.info("检查是否已关注, followerId: {}, followingId: {}", followerId, followingId);
        return ResponseEntity.ok(userService.isFollowing(followerId, followingId));
    }

    @GetMapping("/{id}/followings")
    @Operation(summary = "获取关注列表", description = "获取用户关注的用户列表")
    public ResponseEntity<Page<UserDTO>> getFollowings(@PathVariable Long id, Pageable pageable) {
        log.info("获取关注列表, userId: {}, page: {}, size: {}", id, pageable.getPageNumber(), pageable.getPageSize());
        return ResponseEntity.ok(userService.getFollowings(id, pageable));
    }

    @GetMapping("/{id}/followers")
    @Operation(summary = "获取粉丝列表", description = "获取用户的粉丝列表")
    public ResponseEntity<Page<UserDTO>> getFollowers(@PathVariable Long id, Pageable pageable) {
        log.info("获取粉丝列表, userId: {}, page: {}, size: {}", id, pageable.getPageNumber(), pageable.getPageSize());
        return ResponseEntity.ok(userService.getFollowers(id, pageable));
    }
} 