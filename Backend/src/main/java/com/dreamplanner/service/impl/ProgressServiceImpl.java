package com.dreamplanner.service.impl;

import com.dreamplanner.dto.ProgressDTO;
import com.dreamplanner.entity.Dream;
import com.dreamplanner.entity.Progress;
import com.dreamplanner.entity.Task;
import com.dreamplanner.entity.User;
import com.dreamplanner.repository.DreamRepository;
import com.dreamplanner.repository.ProgressRepository;
import com.dreamplanner.repository.TaskRepository;
import com.dreamplanner.repository.UserRepository;
import com.dreamplanner.service.ProgressService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 进度记录服务实现类
 *
 * @author DreamPlanner
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProgressServiceImpl implements ProgressService {

    private final ProgressRepository progressRepository;
    private final TaskRepository taskRepository;
    private final DreamRepository dreamRepository;
    private final UserRepository userRepository;

    /**
     * 根据任务ID获取进度记录列表
     *
     * @param taskId 任务ID
     * @return 进度记录DTO列表
     */
    @Override
    @Transactional(readOnly = true)
    public List<ProgressDTO> getProgressByTaskId(Long taskId) {
        log.info("获取任务进度记录, taskId: {}", taskId);
        return progressRepository.findByTaskId(taskId).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * 根据梦想ID获取进度记录列表
     *
     * @param dreamId 梦想ID
     * @return 进度记录DTO列表
     */
    @Override
    @Transactional(readOnly = true)
    public List<ProgressDTO> getProgressByDreamId(Long dreamId) {
        log.info("获取梦想进度记录, dreamId: {}", dreamId);
        return progressRepository.findByDreamId(dreamId).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * 根据用户ID获取进度记录列表
     *
     * @param userId 用户ID
     * @return 进度记录DTO列表
     */
    @Override
    @Transactional(readOnly = true)
    public List<ProgressDTO> getProgressByUserId(Long userId) {
        log.info("获取用户进度记录, userId: {}", userId);
        return progressRepository.findByUserId(userId).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * 添加进度记录
     *
     * @param progressDTO 进度记录DTO
     * @return 添加的进度记录DTO
     */
    @Override
    @Transactional
    public ProgressDTO addProgress(ProgressDTO progressDTO) {
        log.info("添加进度记录, userId: {}", progressDTO.getUserId());
        
        // 获取用户
        User user = userRepository.findById(progressDTO.getUserId())
                .orElseThrow(() -> new RuntimeException("用户不存在: " + progressDTO.getUserId()));
        
        // 获取任务（如果有）
        Task task = null;
        if (progressDTO.getTaskId() != null) {
            task = taskRepository.findById(progressDTO.getTaskId())
                    .orElseThrow(() -> new RuntimeException("任务不存在: " + progressDTO.getTaskId()));
        }
        
        // 获取梦想（如果有）
        Dream dream = null;
        if (progressDTO.getDreamId() != null) {
            dream = dreamRepository.findById(progressDTO.getDreamId())
                    .orElseThrow(() -> new RuntimeException("梦想不存在: " + progressDTO.getDreamId()));
        } else if (task != null) {
            // 如果没有指定梦想ID但指定了任务ID，使用任务关联的梦想
            dream = task.getDream();
        }
        
        // 处理图片保存（实际中这里还需要上传图片到文件服务器并获取URL）
        // 为简单起见，现在直接使用前端传来的图片URL字符串
        
        // 创建进度记录实体
        Progress progress = Progress.builder()
                .user(user)
                .task(task)
                .dream(dream)
                .description(progressDTO.getDescription())
                .images(progressDTO.getImages())
                .createdAt(LocalDateTime.now())
                .build();
        
        // 保存进度记录
        Progress savedProgress = progressRepository.save(progress);
        
        // 返回DTO
        return convertToDTO(savedProgress);
    }
    
    /**
     * 将实体转换为DTO
     *
     * @param progress 进度记录实体
     * @return 进度记录DTO
     */
    private ProgressDTO convertToDTO(Progress progress) {
        return ProgressDTO.builder()
                .id(progress.getId())
                .dreamId(progress.getDream() != null ? progress.getDream().getId() : null)
                .taskId(progress.getTask() != null ? progress.getTask().getId() : null)
                .userId(progress.getUser().getId())
                .description(progress.getDescription())
                .images(progress.getImages())
                .createdAt(progress.getCreatedAt())
                .build();
    }
} 