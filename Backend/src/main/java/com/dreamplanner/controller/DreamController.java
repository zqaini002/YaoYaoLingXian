package com.dreamplanner.controller;

import com.dreamplanner.dto.DreamDTO;
import com.dreamplanner.dto.DreamStatsDTO;
import com.dreamplanner.dto.ApiResponseDTO;
import com.dreamplanner.service.DreamService;
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
import java.util.List;

/**
 * 梦想控制器
 *
 * @author DreamPlanner
 */
@RestController
@RequestMapping("/dreams")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "梦想管理", description = "梦想相关接口")
public class DreamController {

    private final DreamService dreamService;

    @GetMapping("/{id}")
    @Operation(summary = "获取梦想详情", description = "根据梦想ID获取梦想详细信息")
    public ResponseEntity<DreamDTO> getDreamById(@PathVariable Long id) {
        log.info("获取梦想详情, id: {}", id);
        return ResponseEntity.ok(dreamService.getDreamById(id));
    }

    @GetMapping("/user/{userId}")
    @Operation(summary = "获取用户的梦想列表", description = "获取指定用户的所有梦想")
    public ResponseEntity<List<DreamDTO>> getDreamsByUserId(@PathVariable Long userId) {
        log.info("获取用户的梦想列表, userId: {}", userId);
        return ResponseEntity.ok(dreamService.getDreamsByUserId(userId));
    }
    
    @GetMapping("/user/{userId}/pageable")
    @Operation(summary = "分页获取用户的梦想列表", description = "分页获取指定用户的所有梦想")
    public ResponseEntity<Page<DreamDTO>> getDreamsByUserIdPageable(
            @PathVariable Long userId, Pageable pageable) {
        log.info("分页获取用户的梦想列表, userId: {}, page: {}, size: {}", 
                userId, pageable.getPageNumber(), pageable.getPageSize());
        return ResponseEntity.ok(dreamService.getDreamsByUserIdPageable(userId, pageable));
    }

    @GetMapping("/user/{userId}/category/{category}")
    @Operation(summary = "获取用户特定分类的梦想", description = "获取指定用户特定分类的梦想列表")
    public ResponseEntity<List<DreamDTO>> getDreamsByUserIdAndCategory(
            @PathVariable Long userId, @PathVariable String category) {
        log.info("获取用户特定分类的梦想, userId: {}, category: {}", userId, category);
        return ResponseEntity.ok(dreamService.getDreamsByUserIdAndCategory(userId, category));
    }

    @GetMapping("/user/{userId}/status/{status}")
    @Operation(summary = "获取用户特定状态的梦想", description = "获取指定用户特定状态的梦想列表")
    public ResponseEntity<List<DreamDTO>> getDreamsByUserIdAndStatus(
            @PathVariable Long userId, @PathVariable Integer status) {
        log.info("获取用户特定状态的梦想, userId: {}, status: {}", userId, status);
        return ResponseEntity.ok(dreamService.getDreamsByUserIdAndStatus(userId, status));
    }

    @GetMapping("/user/{userId}/stats")
    @Operation(summary = "获取用户梦想统计信息", description = "获取指定用户的梦想统计数据")
    public ResponseEntity<ApiResponseDTO<DreamStatsDTO>> getUserDreamStats(@PathVariable Long userId) {
        log.info("获取用户梦想统计信息, userId: {}", userId);
        DreamStatsDTO stats = dreamService.getUserDreamStats(userId);
        return ResponseEntity.ok(ApiResponseDTO.success(stats));
    }

    @PostMapping
    @Operation(summary = "创建梦想", description = "创建新的梦想")
    @PreAuthorize("hasRole('USER') and authentication.principal.id == #dreamDTO.userId")
    public ResponseEntity<DreamDTO> createDream(@Valid @RequestBody DreamDTO dreamDTO) {
        log.info("创建梦想, userId: {}, title: {}", dreamDTO.getUserId(), dreamDTO.getTitle());
        return new ResponseEntity<>(dreamService.createDream(dreamDTO), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    @Operation(summary = "更新梦想", description = "更新指定梦想的信息")
    @PreAuthorize("hasRole('USER') and @dreamService.isDreamOwner(authentication.principal.id, #id)")
    public ResponseEntity<DreamDTO> updateDream(
            @PathVariable Long id, @Valid @RequestBody DreamDTO dreamDTO) {
        log.info("更新梦想, id: {}", id);
        return ResponseEntity.ok(dreamService.updateDream(id, dreamDTO));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "删除梦想", description = "删除指定的梦想")
    @PreAuthorize("hasRole('USER') and @dreamService.isDreamOwner(authentication.principal.id, #id)")
    public ResponseEntity<Void> deleteDream(@PathVariable Long id) {
        log.info("删除梦想, id: {}", id);
        dreamService.deleteDream(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/public")
    @Operation(summary = "获取公开梦想", description = "分页获取所有公开的梦想")
    public ResponseEntity<Page<DreamDTO>> getPublicDreams(Pageable pageable) {
        log.info("获取公开梦想, page: {}, size: {}", pageable.getPageNumber(), pageable.getPageSize());
        return ResponseEntity.ok(dreamService.getPublicDreams(pageable));
    }

    @GetMapping("/search")
    @Operation(summary = "搜索梦想", description = "根据关键词搜索用户的梦想")
    @PreAuthorize("hasRole('USER') and authentication.principal.id == #userId")
    public ResponseEntity<Page<DreamDTO>> searchDreams(
            @RequestParam Long userId, @RequestParam String keyword, Pageable pageable) {
        log.info("搜索梦想, userId: {}, keyword: {}, page: {}, size: {}", 
                userId, keyword, pageable.getPageNumber(), pageable.getPageSize());
        return ResponseEntity.ok(dreamService.searchDreams(userId, keyword, pageable));
    }
} 