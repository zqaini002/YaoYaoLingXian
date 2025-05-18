package com.dreamplanner.service;

import com.dreamplanner.dto.TaskDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.util.List;

/**
 * 任务服务接口
 *
 * @author DreamPlanner
 */
public interface TaskService {

    /**
     * 根据任务ID获取任务
     *
     * @param id 任务ID
     * @return 任务DTO
     */
    TaskDTO getTaskById(Long id);

    /**
     * 根据梦想ID获取任务列表
     *
     * @param dreamId 梦想ID
     * @return 任务DTO列表
     */
    List<TaskDTO> getTasksByDreamId(Long dreamId);

    /**
     * 分页获取梦想下的任务列表
     *
     * @param dreamId  梦想ID
     * @param pageable 分页参数
     * @return 任务DTO分页列表
     */
    Page<TaskDTO> getTasksByDreamIdPageable(Long dreamId, Pageable pageable);

    /**
     * 根据用户ID获取任务列表
     *
     * @param userId 用户ID
     * @return 任务DTO列表
     */
    List<TaskDTO> getTasksByUserId(Long userId);

    /**
     * 分页获取用户的任务列表
     *
     * @param userId   用户ID
     * @param pageable 分页参数
     * @return 任务DTO分页列表
     */
    Page<TaskDTO> getTasksByUserIdPageable(Long userId, Pageable pageable);

    /**
     * 根据梦想ID和状态获取任务列表
     *
     * @param dreamId 梦想ID
     * @param status  状态
     * @return 任务DTO列表
     */
    List<TaskDTO> getTasksByDreamIdAndStatus(Long dreamId, Integer status);

    /**
     * 根据用户ID和状态获取任务列表
     *
     * @param userId 用户ID
     * @param status 状态
     * @return 任务DTO列表
     */
    List<TaskDTO> getTasksByUserIdAndStatus(Long userId, Integer status);

    /**
     * 获取用户今日任务
     *
     * @param userId   用户ID
     * @param pageable 分页参数
     * @return 任务DTO分页列表
     */
    Page<TaskDTO> getTodayTasks(Long userId, Pageable pageable);

    /**
     * 获取用户本周任务
     *
     * @param userId    用户ID
     * @param startDate 开始日期
     * @param endDate   结束日期
     * @param pageable  分页参数
     * @return 任务DTO分页列表
     */
    Page<TaskDTO> getWeekTasks(Long userId, LocalDate startDate, LocalDate endDate, Pageable pageable);

    /**
     * 获取用户即将到期的任务
     *
     * @param userId   用户ID
     * @param days     天数
     * @param pageable 分页参数
     * @return 任务DTO分页列表
     */
    Page<TaskDTO> getUpcomingTasks(Long userId, Integer days, Pageable pageable);

    /**
     * 获取子任务列表
     *
     * @param parentTaskId 父任务ID
     * @return 子任务DTO列表
     */
    List<TaskDTO> getChildTasks(Long parentTaskId);

    /**
     * 创建任务
     *
     * @param taskDTO 任务DTO
     * @return 创建的任务DTO
     */
    TaskDTO createTask(TaskDTO taskDTO);

    /**
     * 更新任务
     *
     * @param id      任务ID
     * @param taskDTO 任务DTO
     * @return 更新后的任务DTO
     */
    TaskDTO updateTask(Long id, TaskDTO taskDTO);

    /**
     * 更新任务状态
     *
     * @param id     任务ID
     * @param status 状态
     * @return 更新后的任务DTO
     */
    TaskDTO updateTaskStatus(Long id, Integer status);

    /**
     * 删除任务
     *
     * @param id 任务ID
     */
    void deleteTask(Long id);

    /**
     * 搜索任务
     *
     * @param userId   用户ID
     * @param keyword  关键词
     * @param pageable 分页参数
     * @return 任务DTO分页列表
     */
    Page<TaskDTO> searchTasks(Long userId, String keyword, Pageable pageable);

    /**
     * 检查任务是否属于用户
     *
     * @param userId 用户ID
     * @param taskId 任务ID
     * @return 是否属于该用户
     */
    boolean isTaskOwner(Long userId, Long taskId);
} 