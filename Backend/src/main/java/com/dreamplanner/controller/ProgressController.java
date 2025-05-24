package com.dreamplanner.controller;

import com.dreamplanner.dto.ProgressDTO;
import com.dreamplanner.service.ProgressService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;

/**
 * 进度记录控制器
 *
 * @author DreamPlanner
 */
@RestController
@RequestMapping("/progress")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "进度记录管理", description = "进度记录相关接口")
public class ProgressController {

    private final ProgressService progressService;

    @GetMapping("/task/{taskId}")
    @Operation(summary = "获取任务进度记录", description = "获取指定任务的所有进度记录")
    public ResponseEntity<List<ProgressDTO>> getProgressByTaskId(@PathVariable Long taskId) {
        log.info("获取任务进度记录, taskId: {}", taskId);
        return ResponseEntity.ok(progressService.getProgressByTaskId(taskId));
    }

    @GetMapping("/dream/{dreamId}")
    @Operation(summary = "获取梦想进度记录", description = "获取指定梦想的所有进度记录")
    public ResponseEntity<List<ProgressDTO>> getProgressByDreamId(@PathVariable Long dreamId) {
        log.info("获取梦想进度记录, dreamId: {}", dreamId);
        return ResponseEntity.ok(progressService.getProgressByDreamId(dreamId));
    }

    @GetMapping("/user/{userId}")
    @Operation(summary = "获取用户进度记录", description = "获取指定用户的所有进度记录")
    @PreAuthorize("hasRole('USER') and authentication.principal.id == #userId")
    public ResponseEntity<List<ProgressDTO>> getProgressByUserId(@PathVariable Long userId) {
        log.info("获取用户进度记录, userId: {}", userId);
        return ResponseEntity.ok(progressService.getProgressByUserId(userId));
    }

    @PostMapping
    @Operation(summary = "添加进度记录", description = "添加新的进度记录")
    @PreAuthorize("hasRole('USER') and authentication.principal.id == #progressDTO.userId")
    public ResponseEntity<ProgressDTO> addProgress(@Valid @RequestBody ProgressDTO progressDTO) {
        log.info("添加进度记录, userId: {}", progressDTO.getUserId());
        return new ResponseEntity<>(progressService.addProgress(progressDTO), HttpStatus.CREATED);
    }

    @PostMapping("/task-progress")
    @Operation(summary = "添加任务进度记录", description = "添加新的任务进度记录，与/progress接口功能相同，兼容客户端")
    @PreAuthorize("hasRole('USER') and authentication.principal.id == #progressDTO.userId")
    public ResponseEntity<ProgressDTO> addTaskProgress(@Valid @RequestBody ProgressDTO progressDTO) {
        log.info("添加任务进度记录, userId: {}", progressDTO.getUserId());
        return new ResponseEntity<>(progressService.addProgress(progressDTO), HttpStatus.CREATED);
    }
} 