package com.dreamplanner.controller;

import com.dreamplanner.dto.TaskDTO;
import com.dreamplanner.service.TaskService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.List;

/**
 * 任务控制器
 *
 * @author DreamPlanner
 */
@RestController
@RequestMapping("/tasks")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "任务管理", description = "任务相关接口")
public class TaskController {

    private final TaskService taskService;

    @GetMapping("/{id}")
    @Operation(summary = "获取任务详情", description = "根据任务ID获取任务详细信息")
    public ResponseEntity<TaskDTO> getTaskById(@PathVariable Long id) {
        log.info("获取任务详情, id: {}", id);
        return ResponseEntity.ok(taskService.getTaskById(id));
    }

    @GetMapping("/dream/{dreamId}")
    @Operation(summary = "获取梦想下的任务列表", description = "获取指定梦想的所有任务")
    public ResponseEntity<List<TaskDTO>> getTasksByDreamId(@PathVariable Long dreamId) {
        log.info("获取梦想下的任务列表, dreamId: {}", dreamId);
        return ResponseEntity.ok(taskService.getTasksByDreamId(dreamId));
    }

    @GetMapping("/dream/{dreamId}/pageable")
    @Operation(summary = "分页获取梦想下的任务列表", description = "分页获取指定梦想的所有任务")
    public ResponseEntity<Page<TaskDTO>> getTasksByDreamIdPageable(
            @PathVariable Long dreamId, Pageable pageable) {
        log.info("分页获取梦想下的任务列表, dreamId: {}, page: {}, size: {}", 
                dreamId, pageable.getPageNumber(), pageable.getPageSize());
        return ResponseEntity.ok(taskService.getTasksByDreamIdPageable(dreamId, pageable));
    }

    @GetMapping("/user/{userId}")
    @Operation(summary = "获取用户的所有任务", description = "获取指定用户的所有任务")
    public ResponseEntity<List<TaskDTO>> getTasksByUserId(@PathVariable Long userId) {
        log.info("获取用户的所有任务, userId: {}", userId);
        return ResponseEntity.ok(taskService.getTasksByUserId(userId));
    }

    @GetMapping("/user/{userId}/pageable")
    @Operation(summary = "分页获取用户的所有任务", description = "分页获取指定用户的所有任务")
    public ResponseEntity<Page<TaskDTO>> getTasksByUserIdPageable(
            @PathVariable Long userId, Pageable pageable) {
        log.info("分页获取用户的所有任务, userId: {}, page: {}, size: {}", 
                userId, pageable.getPageNumber(), pageable.getPageSize());
        return ResponseEntity.ok(taskService.getTasksByUserIdPageable(userId, pageable));
    }

    @GetMapping("/dream/{dreamId}/status/{status}")
    @Operation(summary = "获取梦想下特定状态的任务", description = "获取指定梦想下特定状态的任务列表")
    public ResponseEntity<List<TaskDTO>> getTasksByDreamIdAndStatus(
            @PathVariable Long dreamId, @PathVariable Integer status) {
        log.info("获取梦想下特定状态的任务, dreamId: {}, status: {}", dreamId, status);
        return ResponseEntity.ok(taskService.getTasksByDreamIdAndStatus(dreamId, status));
    }

    @GetMapping("/user/{userId}/status/{status}")
    @Operation(summary = "获取用户特定状态的任务", description = "获取指定用户特定状态的任务列表")
    public ResponseEntity<List<TaskDTO>> getTasksByUserIdAndStatus(
            @PathVariable Long userId, @PathVariable Integer status) {
        log.info("获取用户特定状态的任务, userId: {}, status: {}", userId, status);
        return ResponseEntity.ok(taskService.getTasksByUserIdAndStatus(userId, status));
    }

    @GetMapping("/user/{userId}/today")
    @Operation(summary = "获取用户今日任务", description = "获取指定用户今天的任务")
    public ResponseEntity<Page<TaskDTO>> getTodayTasks(
            @PathVariable Long userId, Pageable pageable) {
        log.info("获取用户今日任务, userId: {}, page: {}, size: {}", 
                userId, pageable.getPageNumber(), pageable.getPageSize());
        return ResponseEntity.ok(taskService.getTodayTasks(userId, pageable));
    }

    @GetMapping("/user/{userId}/upcoming")
    @Operation(summary = "获取用户即将到期的任务", description = "获取指定用户即将到期的任务")
    public ResponseEntity<Page<TaskDTO>> getUpcomingTasks(
            @PathVariable Long userId, 
            @RequestParam(defaultValue = "7") Integer days,
            Pageable pageable) {
        log.info("获取用户即将到期的任务, userId: {}, days: {}, page: {}, size: {}", 
                userId, days, pageable.getPageNumber(), pageable.getPageSize());
        return ResponseEntity.ok(taskService.getUpcomingTasks(userId, days, pageable));
    }
    
    @GetMapping("/user/{userId}/week")
    @Operation(summary = "获取用户本周任务", description = "获取指定用户本周的任务")
    public ResponseEntity<Page<TaskDTO>> getWeekTasks(
            @PathVariable Long userId, 
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            Pageable pageable) {
        log.info("获取用户本周任务, userId: {}, startDate: {}, endDate: {}, page: {}, size: {}", 
                userId, startDate, endDate, pageable.getPageNumber(), pageable.getPageSize());
        return ResponseEntity.ok(taskService.getWeekTasks(userId, startDate, endDate, pageable));
    }

    @GetMapping("/parent/{parentTaskId}")
    @Operation(summary = "获取子任务列表", description = "获取指定父任务的所有子任务")
    public ResponseEntity<List<TaskDTO>> getChildTasks(@PathVariable Long parentTaskId) {
        log.info("获取子任务列表, parentTaskId: {}", parentTaskId);
        return ResponseEntity.ok(taskService.getChildTasks(parentTaskId));
    }

    @PostMapping
    @Operation(summary = "创建任务", description = "创建新的任务")
    @PreAuthorize("hasRole('USER') and authentication.principal.id == #taskDTO.userId")
    public ResponseEntity<TaskDTO> createTask(@Valid @RequestBody TaskDTO taskDTO) {
        log.info("创建任务, userId: {}, dreamId: {}, title: {}", 
                taskDTO.getUserId(), taskDTO.getDreamId(), taskDTO.getTitle());
        return new ResponseEntity<>(taskService.createTask(taskDTO), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    @Operation(summary = "更新任务", description = "更新指定任务的信息")
    @PreAuthorize("hasRole('USER') and @taskService.isTaskOwner(authentication.principal.id, #id)")
    public ResponseEntity<TaskDTO> updateTask(
            @PathVariable Long id, @Valid @RequestBody TaskDTO taskDTO) {
        log.info("更新任务, id: {}", id);
        return ResponseEntity.ok(taskService.updateTask(id, taskDTO));
    }

    @PutMapping("/{id}/status/{status}")
    @Operation(summary = "更新任务状态", description = "更新指定任务的状态")
    @PreAuthorize("hasRole('USER') and @taskService.isTaskOwner(authentication.principal.id, #id)")
    public ResponseEntity<TaskDTO> updateTaskStatus(
            @PathVariable Long id, @PathVariable Integer status) {
        log.info("更新任务状态, id: {}, status: {}", id, status);
        return ResponseEntity.ok(taskService.updateTaskStatus(id, status));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "删除任务", description = "删除指定的任务")
    @PreAuthorize("hasRole('USER') and @taskService.isTaskOwner(authentication.principal.id, #id)")
    public ResponseEntity<Void> deleteTask(@PathVariable Long id) {
        log.info("删除任务, id: {}", id);
        taskService.deleteTask(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/search")
    @Operation(summary = "搜索任务", description = "根据关键词搜索用户的任务")
    @PreAuthorize("hasRole('USER') and authentication.principal.id == #userId")
    public ResponseEntity<Page<TaskDTO>> searchTasks(
            @RequestParam Long userId, @RequestParam String keyword, Pageable pageable) {
        log.info("搜索任务, userId: {}, keyword: {}, page: {}, size: {}", 
                userId, keyword, pageable.getPageNumber(), pageable.getPageSize());
        return ResponseEntity.ok(taskService.searchTasks(userId, keyword, pageable));
    }
} 