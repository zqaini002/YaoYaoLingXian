package com.dreamplanner.service.impl;

import com.dreamplanner.dto.TaskDTO;
import com.dreamplanner.entity.Dream;
import com.dreamplanner.entity.Task;
import com.dreamplanner.entity.User;
import com.dreamplanner.repository.DreamRepository;
import com.dreamplanner.repository.TaskRepository;
import com.dreamplanner.repository.UserRepository;
import com.dreamplanner.service.TaskService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 任务服务实现类
 *
 * @author DreamPlanner
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TaskServiceImpl implements TaskService {

    private final TaskRepository taskRepository;
    private final DreamRepository dreamRepository;
    private final UserRepository userRepository;

    /**
     * 根据任务ID获取任务
     *
     * @param id 任务ID
     * @return 任务DTO
     */
    @Override
    @Transactional(readOnly = true)
    public TaskDTO getTaskById(Long id) {
        log.info("获取任务详情, id: {}", id);
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("任务不存在: " + id));
        return convertToDTO(task);
    }

    /**
     * 根据梦想ID获取任务列表
     *
     * @param dreamId 梦想ID
     * @return 任务DTO列表
     */
    @Override
    @Transactional(readOnly = true)
    public List<TaskDTO> getTasksByDreamId(Long dreamId) {
        log.info("获取梦想下的任务列表, dreamId: {}", dreamId);
        return taskRepository.findByDreamId(dreamId).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * 分页获取梦想下的任务列表
     *
     * @param dreamId  梦想ID
     * @param pageable 分页参数
     * @return 任务DTO分页列表
     */
    @Override
    @Transactional(readOnly = true)
    public Page<TaskDTO> getTasksByDreamIdPageable(Long dreamId, Pageable pageable) {
        log.info("分页获取梦想下的任务列表, dreamId: {}, page: {}, size: {}", 
                dreamId, pageable.getPageNumber(), pageable.getPageSize());
        return taskRepository.findByDreamId(dreamId, pageable)
                .map(this::convertToDTO);
    }

    /**
     * 根据用户ID获取任务列表
     *
     * @param userId 用户ID
     * @return 任务DTO列表
     */
    @Override
    @Transactional(readOnly = true)
    public List<TaskDTO> getTasksByUserId(Long userId) {
        log.info("获取用户的所有任务, userId: {}", userId);
        return taskRepository.findByUserId(userId).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * 分页获取用户的任务列表
     *
     * @param userId   用户ID
     * @param pageable 分页参数
     * @return 任务DTO分页列表
     */
    @Override
    @Transactional(readOnly = true)
    public Page<TaskDTO> getTasksByUserIdPageable(Long userId, Pageable pageable) {
        log.info("分页获取用户的所有任务, userId: {}, page: {}, size: {}", 
                userId, pageable.getPageNumber(), pageable.getPageSize());
        return taskRepository.findByUserId(userId, pageable)
                .map(this::convertToDTO);
    }

    /**
     * 根据梦想ID和状态获取任务列表
     *
     * @param dreamId 梦想ID
     * @param status  状态
     * @return 任务DTO列表
     */
    @Override
    @Transactional(readOnly = true)
    public List<TaskDTO> getTasksByDreamIdAndStatus(Long dreamId, Integer status) {
        log.info("获取梦想下特定状态的任务, dreamId: {}, status: {}", dreamId, status);
        return taskRepository.findByDreamIdAndStatus(dreamId, status).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * 根据用户ID和状态获取任务列表
     *
     * @param userId 用户ID
     * @param status 状态
     * @return 任务DTO列表
     */
    @Override
    @Transactional(readOnly = true)
    public List<TaskDTO> getTasksByUserIdAndStatus(Long userId, Integer status) {
        log.info("获取用户特定状态的任务, userId: {}, status: {}", userId, status);
        return taskRepository.findByUserIdAndStatus(userId, status).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * 获取用户今日任务
     * 
     * 现在返回更广泛的任务集合：
     * 1. 今天开始或今天截止的任务（严格意义的今日任务）
     * 2. 已经开始但尚未完成的任务（进行中的任务）
     * 3. 7天内即将到期的任务（即将到期任务）
     * 
     * 结果按以下顺序排序：
     * 1. 今天截止的任务优先
     * 2. 今天开始的任务次之
     * 3. 按优先级排序
     * 4. 有截止日期的优先于无截止日期
     * 5. 按截止日期升序
     *
     * @param userId   用户ID
     * @param pageable 分页参数
     * @return 任务DTO分页列表
     */
    @Override
    @Transactional(readOnly = true)
    public Page<TaskDTO> getTodayTasks(Long userId, Pageable pageable) {
        log.info("获取用户今日任务, userId: {}, page: {}, size: {}", 
                userId, pageable.getPageNumber(), pageable.getPageSize());
        
        try {
            // 计算当前日期和7天后的日期
            LocalDate today = LocalDate.now();
            LocalDate endDate = today.plusDays(7); // 7天后的日期
            
            return taskRepository.findTodayTasks(userId, today, endDate, pageable)
                    .map(task -> {
                        TaskDTO dto = convertToDTO(task);
                        
                        // 根据任务的日期特征设置相应标记
                        if (task.getStartDate() != null && task.getStartDate().equals(today) ||
                            task.getDueDate() != null && task.getDueDate().equals(today)) {
                            dto.setIsTodayTask(true);
                        } else if (task.getDueDate() != null && task.getDueDate().isAfter(today) &&
                                   task.getDueDate().isBefore(today.plusDays(8))) {
                            dto.setIsUpcomingTask(true);
                        }
                        
                        return dto;
                    });
        } catch (Exception e) {
            log.error("获取今日任务失败, userId: {}", userId, e);
            return Page.empty(pageable);
        }
    }

    /**
     * 获取用户本周任务
     *
     * @param userId    用户ID
     * @param startDate 开始日期
     * @param endDate   结束日期
     * @param pageable  分页参数
     * @return 任务DTO分页列表
     */
    @Override
    @Transactional(readOnly = true)
    public Page<TaskDTO> getWeekTasks(Long userId, LocalDate startDate, LocalDate endDate, Pageable pageable) {
        log.info("获取用户本周任务, userId: {}, startDate: {}, endDate: {}, page: {}, size: {}", 
                userId, startDate, endDate, pageable.getPageNumber(), pageable.getPageSize());
        return taskRepository.findWeekTasks(userId, startDate, endDate, pageable)
                .map(this::convertToDTO);
    }

    /**
     * 获取用户即将到期的任务
     *
     * @param userId   用户ID
     * @param days     天数
     * @param pageable 分页参数
     * @return 任务DTO分页列表
     */
    @Override
    @Transactional(readOnly = true)
    public Page<TaskDTO> getUpcomingTasks(Long userId, Integer days, Pageable pageable) {
        log.info("获取用户即将到期的任务, userId: {}, days: {}, page: {}, size: {}", 
                userId, days, pageable.getPageNumber(), pageable.getPageSize());
        
        try {
            LocalDate dueDate = LocalDate.now().plusDays(days);
            return taskRepository.findUpcomingTasks(userId, dueDate, pageable)
                    .map(task -> {
                        TaskDTO dto = convertToDTO(task);
                        
                        // 检查是否已过期
                        if (task.getDueDate() != null && task.getDueDate().isBefore(LocalDate.now())) {
                            dto.setIsOverdue(true);
                        } else {
                            dto.setIsOverdue(false);
                        }
                        
                        return dto;
                    });
        } catch (Exception e) {
            log.error("获取即将到期任务失败, userId: {}", userId, e);
            return Page.empty(pageable);
        }
    }

    /**
     * 获取子任务列表
     *
     * @param parentTaskId 父任务ID
     * @return 子任务DTO列表
     */
    @Override
    @Transactional(readOnly = true)
    public List<TaskDTO> getChildTasks(Long parentTaskId) {
        log.info("获取子任务列表, parentTaskId: {}", parentTaskId);
        return taskRepository.findByParentTaskId(parentTaskId).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * 创建任务
     *
     * @param taskDTO 任务DTO
     * @return 创建的任务DTO
     */
    @Override
    @Transactional
    public TaskDTO createTask(TaskDTO taskDTO) {
        log.info("创建任务, userId: {}, dreamId: {}, title: {}", 
                taskDTO.getUserId(), taskDTO.getDreamId(), taskDTO.getTitle());
        
        // 获取用户
        User user = userRepository.findById(taskDTO.getUserId())
                .orElseThrow(() -> new RuntimeException("用户不存在: " + taskDTO.getUserId()));
        
        // 获取梦想
        Dream dream = dreamRepository.findById(taskDTO.getDreamId())
                .orElseThrow(() -> new RuntimeException("梦想不存在: " + taskDTO.getDreamId()));
        
        // 获取父任务（如果有）
        Task parentTask = null;
        if (taskDTO.getParentTaskId() != null) {
            parentTask = taskRepository.findById(taskDTO.getParentTaskId())
                    .orElseThrow(() -> new RuntimeException("父任务不存在: " + taskDTO.getParentTaskId()));
        }
        
        // 构建任务实体
        Task task = Task.builder()
                .dream(dream)
                .user(user)
                .title(taskDTO.getTitle())
                .description(taskDTO.getDescription())
                .status(taskDTO.getStatus())
                .priority(taskDTO.getPriority())
                .startDate(taskDTO.getStartDate())
                .dueDate(taskDTO.getDueDate())
                .completedAt(taskDTO.getCompletedAt())
                .reminderTime(taskDTO.getReminderTime())
                .parentTask(parentTask)
                .build();
        
        // 保存任务
        Task savedTask = taskRepository.save(task);
        
        // 更新梦想的完成率和状态
        if (dream != null) {
            log.info("创建新任务，更新梦想[{}]的完成率和状态", dream.getId());
            
            // 获取梦想下所有任务(包括刚刚创建的任务)
            List<Task> dreamTasks = taskRepository.findByDreamId(dream.getId());
            
            // 计算已完成任务数量和任务总数
            long totalTasks = dreamTasks.size();
            long completedTasks = dreamTasks.stream()
                    .filter(t -> t.getStatus() == 2)
                    .count();
            
            // 计算新的完成率
            BigDecimal completionRate = BigDecimal.ZERO;
            if (totalTasks > 0) {
                completionRate = BigDecimal.valueOf(completedTasks)
                        .multiply(BigDecimal.valueOf(100))
                        .divide(BigDecimal.valueOf(totalTasks), 0, RoundingMode.HALF_UP);
            }
            
            // 更新梦想的完成率
            dream.setCompletionRate(completionRate);
            
            // 在创建新任务时，检查梦想状态是否需要更新
            if (dream.getStatus() == 2 && totalTasks > completedTasks) {
                // 如果梦想已完成但新增了未完成任务，将状态更新为进行中
                log.info("梦想[{}]新增未完成任务，更新状态为进行中", dream.getId());
                dream.setStatus(1); // 进行中
            }
            
            dreamRepository.save(dream);
            
            log.info("更新梦想[{}]完成率为: {}%, 状态为: {}", 
                dream.getId(), completionRate, dream.getStatus());
        }
        
        // 返回DTO
        return convertToDTO(savedTask);
    }

    /**
     * 更新任务
     *
     * @param id      任务ID
     * @param taskDTO 任务DTO
     * @return 更新后的任务DTO
     */
    @Override
    @Transactional
    public TaskDTO updateTask(Long id, TaskDTO taskDTO) {
        log.info("更新任务, id: {}", id);
        
        // 获取任务
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("任务不存在: " + id));
        
        // 获取梦想（如果有变更）
        if (!task.getDream().getId().equals(taskDTO.getDreamId())) {
            Dream dream = dreamRepository.findById(taskDTO.getDreamId())
                    .orElseThrow(() -> new RuntimeException("梦想不存在: " + taskDTO.getDreamId()));
            task.setDream(dream);
        }
        
        // 获取父任务（如果有变更）
        if (taskDTO.getParentTaskId() != null && 
                (task.getParentTask() == null || !task.getParentTask().getId().equals(taskDTO.getParentTaskId()))) {
            Task parentTask = taskRepository.findById(taskDTO.getParentTaskId())
                    .orElseThrow(() -> new RuntimeException("父任务不存在: " + taskDTO.getParentTaskId()));
            task.setParentTask(parentTask);
        } else if (taskDTO.getParentTaskId() == null && task.getParentTask() != null) {
            task.setParentTask(null);
        }
        
        // 更新任务属性
        task.setTitle(taskDTO.getTitle());
        task.setDescription(taskDTO.getDescription());
        task.setStatus(taskDTO.getStatus());
        task.setPriority(taskDTO.getPriority());
        task.setStartDate(taskDTO.getStartDate());
        task.setDueDate(taskDTO.getDueDate());
        task.setReminderTime(taskDTO.getReminderTime());
        
        // 如果状态变成已完成，设置完成时间
        if (taskDTO.getStatus() == 2 && task.getCompletedAt() == null) {
            task.setCompletedAt(taskDTO.getCompletedAt() != null ? taskDTO.getCompletedAt() : LocalDate.now().atStartOfDay());
        } else if (taskDTO.getStatus() != 2) {
            task.setCompletedAt(null);
        }
        
        // 保存任务
        Task updatedTask = taskRepository.save(task);
        
        // 返回DTO
        return convertToDTO(updatedTask);
    }

    /**
     * 更新任务状态
     *
     * @param id     任务ID
     * @param status 状态
     * @return 更新后的任务DTO
     */
    @Override
    @Transactional
    public TaskDTO updateTaskStatus(Long id, Integer status) {
        log.info("更新任务状态, id: {}, status: {}", id, status);
        
        // 获取任务
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("任务不存在: " + id));
        
        // 保存任务原来的状态，用于判断是否需要更新梦想完成率
        Integer oldStatus = task.getStatus();
        
        // 更新状态
        task.setStatus(status);
        
        // 如果状态为已完成，设置完成时间
        if (status == 2 && task.getCompletedAt() == null) {
            task.setCompletedAt(LocalDate.now().atStartOfDay());
        } else if (status != 2) {
            task.setCompletedAt(null);
        }
        
        // 保存任务
        Task updatedTask = taskRepository.save(task);
        
        // 如果任务状态发生变化，更新对应梦想的完成率和状态
        if (!oldStatus.equals(status)) {
            // 获取关联的梦想
            Dream dream = task.getDream();
            if (dream != null) {
                log.info("任务状态变更，更新梦想[{}]的完成率和状态", dream.getId());
                
                // 获取梦想下所有任务
                List<Task> dreamTasks = taskRepository.findByDreamId(dream.getId());
                
                // 计算已完成任务数量和任务总数
                long totalTasks = dreamTasks.size();
                long completedTasks = dreamTasks.stream()
                        .filter(t -> t.getStatus() == 2)
                        .count();
                
                // 计算新的完成率
                BigDecimal completionRate = BigDecimal.ZERO;
                if (totalTasks > 0) {
                    completionRate = BigDecimal.valueOf(completedTasks)
                            .multiply(BigDecimal.valueOf(100))
                            .divide(BigDecimal.valueOf(totalTasks), 0, RoundingMode.HALF_UP);
                }
                
                // 更新梦想的完成率
                dream.setCompletionRate(completionRate);
                
                // 检查是否所有任务都已完成，如果是则将梦想状态设置为已完成(2)
                if (totalTasks > 0 && completedTasks == totalTasks) {
                    log.info("梦想[{}]的所有任务已完成，更新梦想状态为已完成", dream.getId());
                    dream.setStatus(2); // 已完成
                } else if (dream.getStatus() == 2 && completedTasks < totalTasks) {
                    // 如果梦想状态为已完成，但不是所有任务都完成，则修改为进行中
                    log.info("梦想[{}]有未完成任务，更新梦想状态为进行中", dream.getId());
                    dream.setStatus(1); // 进行中
                }
                
                dreamRepository.save(dream);
                
                log.info("更新梦想[{}]完成率为: {}%, 状态为: {}", 
                    dream.getId(), completionRate, dream.getStatus());
            }
        }
        
        // 返回DTO
        return convertToDTO(updatedTask);
    }

    /**
     * 删除任务
     *
     * @param id 任务ID
     */
    @Override
    @Transactional
    public void deleteTask(Long id) {
        log.info("删除任务, id: {}", id);
        
        // 获取任务以获得关联的梦想ID
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("任务不存在: " + id));
        
        // 保存梦想引用，以便在删除任务后更新完成率
        Long dreamId = null;
        if (task.getDream() != null) {
            dreamId = task.getDream().getId();
        }
        
        // 删除任务
        taskRepository.deleteById(id);
        
        // 如果有关联的梦想，更新其完成率和状态
        if (dreamId != null) {
            log.info("删除任务后，更新梦想[{}]的完成率和状态", dreamId);
            
            // 获取梦想
            Dream dream = dreamRepository.findById(dreamId)
                    .orElse(null);
            
            if (dream != null) {
                // 获取梦想下剩余的所有任务
                List<Task> dreamTasks = taskRepository.findByDreamId(dreamId);
                
                // 计算已完成任务数量和任务总数
                long totalTasks = dreamTasks.size();
                long completedTasks = dreamTasks.stream()
                        .filter(t -> t.getStatus() == 2)
                        .count();
                
                // 计算新的完成率
                BigDecimal completionRate = BigDecimal.ZERO;
                if (totalTasks > 0) {
                    completionRate = BigDecimal.valueOf(completedTasks)
                            .multiply(BigDecimal.valueOf(100))
                            .divide(BigDecimal.valueOf(totalTasks), 0, RoundingMode.HALF_UP);
                }
                
                // 更新梦想的完成率
                dream.setCompletionRate(completionRate);
                
                // 检查梦想状态是否需要更新
                if (totalTasks > 0 && completedTasks == totalTasks) {
                    // 如果剩余任务全部完成，将梦想状态设置为已完成
                    log.info("梦想[{}]的所有剩余任务都已完成，更新状态为已完成", dreamId);
                    dream.setStatus(2); // 已完成
                } else if (dream.getStatus() == 2 && completedTasks < totalTasks) {
                    // 如果梦想为已完成但剩余任务有未完成的，修改为进行中
                    log.info("梦想[{}]有未完成任务，更新状态为进行中", dreamId);
                    dream.setStatus(1); // 进行中
                } else if (totalTasks == 0) {
                    // 如果没有任务了，则保持当前状态
                    log.info("梦想[{}]没有任务，保持当前状态", dreamId);
                }
                
                dreamRepository.save(dream);
                
                log.info("更新梦想[{}]完成率为: {}%, 状态为: {}", dreamId, completionRate, dream.getStatus());
            }
        }
    }

    /**
     * 搜索任务
     *
     * @param userId   用户ID
     * @param keyword  关键词
     * @param pageable 分页参数
     * @return 任务DTO分页列表
     */
    @Override
    @Transactional(readOnly = true)
    public Page<TaskDTO> searchTasks(Long userId, String keyword, Pageable pageable) {
        log.info("搜索任务, userId: {}, keyword: {}, page: {}, size: {}", 
                userId, keyword, pageable.getPageNumber(), pageable.getPageSize());
        return taskRepository.searchByKeyword(userId, keyword, pageable)
                .map(this::convertToDTO);
    }

    /**
     * 检查任务是否属于用户
     *
     * @param userId 用户ID
     * @param taskId 任务ID
     * @return 是否属于该用户
     */
    @Override
    @Transactional(readOnly = true)
    public boolean isTaskOwner(Long userId, Long taskId) {
        log.info("检查任务是否属于用户, userId: {}, taskId: {}", userId, taskId);
        Task task = taskRepository.findById(taskId).orElse(null);
        return task != null && task.getUser().getId().equals(userId);
    }

    /**
     * 将任务实体转换为DTO
     *
     * @param task 任务实体
     * @return 任务DTO
     */
    private TaskDTO convertToDTO(Task task) {
        // 获取子任务
        List<TaskDTO> childTasks = null;
        if (task.getChildTasks() != null && !task.getChildTasks().isEmpty()) {
            childTasks = task.getChildTasks().stream()
                    .map(this::convertChildToDTO)
                    .collect(Collectors.toList());
        }
        
        // 构建并返回任务DTO
        return TaskDTO.builder()
                .id(task.getId())
                .dreamId(task.getDream().getId())
                .dreamTitle(task.getDream().getTitle())
                .userId(task.getUser().getId())
                .title(task.getTitle())
                .description(task.getDescription())
                .status(task.getStatus())
                .priority(task.getPriority())
                .startDate(task.getStartDate())
                .dueDate(task.getDueDate())
                .completedAt(task.getCompletedAt())
                .reminderTime(task.getReminderTime())
                .parentTaskId(task.getParentTask() != null ? task.getParentTask().getId() : null)
                .createdAt(task.getCreatedAt())
                .updatedAt(task.getUpdatedAt())
                .childTasks(childTasks)
                .isTodayTask(false)
                .isOverdue(task.getDueDate() != null && task.getDueDate().isBefore(LocalDate.now()) && task.getStatus() != 2)
                .build();
    }
    
    /**
     * 将子任务实体转换为DTO（简化版，避免递归）
     *
     * @param childTask 子任务实体
     * @return 子任务DTO
     */
    private TaskDTO convertChildToDTO(Task childTask) {
        return TaskDTO.builder()
                .id(childTask.getId())
                .dreamId(childTask.getDream().getId())
                .dreamTitle(childTask.getDream().getTitle())
                .userId(childTask.getUser().getId())
                .title(childTask.getTitle())
                .description(childTask.getDescription())
                .status(childTask.getStatus())
                .priority(childTask.getPriority())
                .startDate(childTask.getStartDate())
                .dueDate(childTask.getDueDate())
                .completedAt(childTask.getCompletedAt())
                .reminderTime(childTask.getReminderTime())
                .parentTaskId(childTask.getParentTask().getId())
                .createdAt(childTask.getCreatedAt())
                .updatedAt(childTask.getUpdatedAt())
                .isTodayTask(false)
                .isOverdue(childTask.getDueDate() != null && childTask.getDueDate().isBefore(LocalDate.now()) && childTask.getStatus() != 2)
                .build();
    }
} 