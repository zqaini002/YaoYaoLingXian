package com.dreamplanner.service;

import com.dreamplanner.dto.ProgressDTO;

import java.util.List;

/**
 * 进度记录服务接口
 *
 * @author DreamPlanner
 */
public interface ProgressService {

    /**
     * 根据任务ID获取进度记录列表
     *
     * @param taskId 任务ID
     * @return 进度记录DTO列表
     */
    List<ProgressDTO> getProgressByTaskId(Long taskId);

    /**
     * 根据梦想ID获取进度记录列表
     *
     * @param dreamId 梦想ID
     * @return 进度记录DTO列表
     */
    List<ProgressDTO> getProgressByDreamId(Long dreamId);

    /**
     * 根据用户ID获取进度记录列表
     *
     * @param userId 用户ID
     * @return 进度记录DTO列表
     */
    List<ProgressDTO> getProgressByUserId(Long userId);

    /**
     * 添加进度记录
     *
     * @param progressDTO 进度记录DTO
     * @return 添加的进度记录DTO
     */
    ProgressDTO addProgress(ProgressDTO progressDTO);
} 