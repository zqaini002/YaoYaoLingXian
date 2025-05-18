package com.dreamplanner.service.impl;

import com.dreamplanner.dto.DreamDTO;
import com.dreamplanner.dto.DreamStatsDTO;
import com.dreamplanner.dto.ResourceDTO;
import com.dreamplanner.dto.TaskDTO;
import com.dreamplanner.entity.Dream;
import com.dreamplanner.entity.DreamResource;
import com.dreamplanner.entity.DreamTag;
import com.dreamplanner.entity.Resource;
import com.dreamplanner.entity.Tag;
import com.dreamplanner.entity.Task;
import com.dreamplanner.entity.User;
import com.dreamplanner.repository.DreamRepository;
import com.dreamplanner.repository.TaskRepository;
import com.dreamplanner.repository.UserRepository;
import com.dreamplanner.service.DreamService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 梦想服务实现类
 *
 * @author DreamPlanner
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DreamServiceImpl implements DreamService {

    private final DreamRepository dreamRepository;
    private final UserRepository userRepository;
    private final TaskRepository taskRepository;

    /**
     * 根据梦想ID获取梦想
     *
     * @param id 梦想ID
     * @return 梦想DTO
     */
    @Override
    @Transactional(readOnly = true)
    public DreamDTO getDreamById(Long id) {
        log.info("获取梦想详情, id: {}", id);
        Dream dream = dreamRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("梦想不存在: " + id));
        return convertToDTO(dream);
    }

    /**
     * 根据用户ID获取梦想列表
     *
     * @param userId 用户ID
     * @return 梦想DTO列表
     */
    @Override
    @Transactional(readOnly = true)
    public List<DreamDTO> getDreamsByUserId(Long userId) {
        log.info("获取用户的梦想列表, userId: {}", userId);
        return dreamRepository.findByUserId(userId).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * 分页获取用户的梦想列表
     *
     * @param userId   用户ID
     * @param pageable 分页参数
     * @return 梦想DTO分页列表
     */
    @Override
    @Transactional(readOnly = true)
    public Page<DreamDTO> getDreamsByUserIdPageable(Long userId, Pageable pageable) {
        log.info("分页获取用户的梦想列表, userId: {}, page: {}, size: {}", 
                userId, pageable.getPageNumber(), pageable.getPageSize());
        return dreamRepository.findByUserId(userId, pageable)
                .map(this::convertToDTO);
    }

    /**
     * 根据用户ID和分类获取梦想列表
     *
     * @param userId   用户ID
     * @param category 分类
     * @return 梦想DTO列表
     */
    @Override
    @Transactional(readOnly = true)
    public List<DreamDTO> getDreamsByUserIdAndCategory(Long userId, String category) {
        log.info("获取用户特定分类的梦想, userId: {}, category: {}", userId, category);
        return dreamRepository.findByUserIdAndCategory(userId, category).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * 根据用户ID和状态获取梦想列表
     *
     * @param userId 用户ID
     * @param status 状态
     * @return 梦想DTO列表
     */
    @Override
    @Transactional(readOnly = true)
    public List<DreamDTO> getDreamsByUserIdAndStatus(Long userId, Integer status) {
        log.info("获取用户特定状态的梦想, userId: {}, status: {}", userId, status);
        return dreamRepository.findByUserIdAndStatus(userId, status).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * 获取用户梦想统计信息
     *
     * @param userId 用户ID
     * @return 梦想统计DTO
     */
    @Override
    @Transactional(readOnly = true)
    public DreamStatsDTO getUserDreamStats(Long userId) {
        log.info("获取用户梦想统计信息, userId: {}", userId);
        
        // 获取用户所有梦想
        List<Dream> dreams = dreamRepository.findByUserId(userId);
        
        // 计算统计数据
        long totalDreams = dreams.size();
        
        // 计算不同状态的梦想数
        long inProgressDreams = dreams.stream().filter(d -> d.getStatus() == 1).count();
        long completedDreams = dreams.stream().filter(d -> d.getStatus() == 2).count();
        long abandonedDreams = dreams.stream().filter(d -> d.getStatus() == 0).count();
        
        // 计算梦想完成率
        BigDecimal dreamCompletionRate = BigDecimal.ZERO;
        if (totalDreams > 0) {
            dreamCompletionRate = BigDecimal.valueOf(completedDreams)
                    .divide(BigDecimal.valueOf(totalDreams), 2, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100));
        }
        
        // 获取任务统计
        long totalTasks = taskRepository.countByUserId(userId);
        long completedTasks = taskRepository.countByUserIdAndStatus(userId, 2);
        
        // 计算任务完成率
        BigDecimal taskCompletionRate = BigDecimal.ZERO;
        if (totalTasks > 0) {
            taskCompletionRate = BigDecimal.valueOf(completedTasks)
                    .divide(BigDecimal.valueOf(totalTasks), 2, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100));
        }
        
        // 构建并返回梦想统计DTO
        return DreamStatsDTO.builder()
                .userId(userId)
                .totalDreams(totalDreams)
                .inProgressDreams(inProgressDreams)
                .completedDreams(completedDreams)
                .abandonedDreams(abandonedDreams)
                .dreamCompletionRate(dreamCompletionRate)
                .totalTasks(totalTasks)
                .completedTasks(completedTasks)
                .taskCompletionRate(taskCompletionRate)
                .build();
    }

    /**
     * 创建梦想
     *
     * @param dreamDTO 梦想DTO
     * @return 创建的梦想DTO
     */
    @Override
    @Transactional
    public DreamDTO createDream(DreamDTO dreamDTO) {
        log.info("创建梦想, userId: {}, title: {}", dreamDTO.getUserId(), dreamDTO.getTitle());
        
        // 获取用户
        User user = userRepository.findById(dreamDTO.getUserId())
                .orElseThrow(() -> new RuntimeException("用户不存在: " + dreamDTO.getUserId()));
        
        // 构建梦想实体
        Dream dream = Dream.builder()
                .user(user)
                .title(dreamDTO.getTitle())
                .description(dreamDTO.getDescription())
                .category(dreamDTO.getCategory())
                .priority(dreamDTO.getPriority())
                .status(dreamDTO.getStatus())
                // 不使用前端传递的完成率，初始值设为0
                .completionRate(BigDecimal.ZERO)
                .deadline(dreamDTO.getDeadline())
                .expectedDays(dreamDTO.getExpectedDays())
                .imageUrl(dreamDTO.getImageUrl())
                .isPublic(dreamDTO.getIsPublic())
                .tags(new HashSet<>())
                .resources(new HashSet<>())
                .tasks(new HashSet<>())
                .posts(new HashSet<>())
                .build();
        
        // 保存梦想
        Dream savedDream = dreamRepository.save(dream);
        
        // 返回DTO
        return convertToDTO(savedDream);
    }

    /**
     * 更新梦想
     *
     * @param id       梦想ID
     * @param dreamDTO 梦想DTO
     * @return 更新后的梦想DTO
     */
    @Override
    @Transactional
    public DreamDTO updateDream(Long id, DreamDTO dreamDTO) {
        log.info("更新梦想, id: {}", id);
        
        // 获取梦想
        Dream dream = dreamRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("梦想不存在: " + id));
        
        // 更新梦想属性
        dream.setTitle(dreamDTO.getTitle());
        dream.setDescription(dreamDTO.getDescription());
        dream.setCategory(dreamDTO.getCategory());
        dream.setPriority(dreamDTO.getPriority());
        dream.setStatus(dreamDTO.getStatus());
        dream.setDeadline(dreamDTO.getDeadline());
        dream.setExpectedDays(dreamDTO.getExpectedDays());
        dream.setImageUrl(dreamDTO.getImageUrl());
        dream.setIsPublic(dreamDTO.getIsPublic());
        
        // 保存梦想
        Dream updatedDream = dreamRepository.save(dream);
        
        // 返回DTO
        return convertToDTO(updatedDream);
    }

    /**
     * 删除梦想
     *
     * @param id 梦想ID
     */
    @Override
    @Transactional
    public void deleteDream(Long id) {
        log.info("删除梦想, id: {}", id);
        
        // 检查梦想是否存在
        if (!dreamRepository.existsById(id)) {
            throw new RuntimeException("梦想不存在: " + id);
        }
        
        // 删除梦想
        dreamRepository.deleteById(id);
    }

    /**
     * 获取公开的梦想列表
     *
     * @param pageable 分页参数
     * @return 公开梦想DTO分页列表
     */
    @Override
    @Transactional(readOnly = true)
    public Page<DreamDTO> getPublicDreams(Pageable pageable) {
        log.info("获取公开梦想, page: {}, size: {}", pageable.getPageNumber(), pageable.getPageSize());
        return dreamRepository.findByIsPublic(1, pageable)
                .map(this::convertToDTO);
    }

    /**
     * 搜索梦想
     *
     * @param userId   用户ID
     * @param keyword  关键词
     * @param pageable 分页参数
     * @return 梦想DTO分页列表
     */
    @Override
    @Transactional(readOnly = true)
    public Page<DreamDTO> searchDreams(Long userId, String keyword, Pageable pageable) {
        log.info("搜索梦想, userId: {}, keyword: {}, page: {}, size: {}", 
                userId, keyword, pageable.getPageNumber(), pageable.getPageSize());
        return dreamRepository.searchByKeyword(userId, keyword, pageable)
                .map(this::convertToDTO);
    }

    /**
     * 检查梦想是否属于用户
     *
     * @param userId  用户ID
     * @param dreamId 梦想ID
     * @return 是否属于该用户
     */
    @Override
    @Transactional(readOnly = true)
    public boolean isDreamOwner(Long userId, Long dreamId) {
        log.info("检查梦想是否属于用户, userId: {}, dreamId: {}", userId, dreamId);
        Dream dream = dreamRepository.findById(dreamId).orElse(null);
        return dream != null && dream.getUser().getId().equals(userId);
    }

    /**
     * 将梦想实体转换为DTO
     *
     * @param dream 梦想实体
     * @return 梦想DTO
     */
    private DreamDTO convertToDTO(Dream dream) {
        // 获取标签
        List<String> tags = dream.getTags() != null ? 
            dream.getTags().stream()
                .map(Tag::getName)
                .collect(Collectors.toList()) : 
            new ArrayList<>();
        
        // 获取资源
        List<ResourceDTO> resources = dream.getResources() != null ? 
            dream.getResources().stream()
                .map(resource -> ResourceDTO.builder()
                        .id(resource.getId())
                        .title(resource.getTitle())
                        .description(resource.getDescription())
                        .type(resource.getType())
                        .category(resource.getCategory())
                        .url(resource.getUrl())
                        .imageUrl(resource.getImageUrl())
                        .status(resource.getStatus())
                        .createdAt(resource.getCreatedAt())
                        .updatedAt(resource.getUpdatedAt())
                        .build())
                .collect(Collectors.toList()) :
            new ArrayList<>();
            
        // 实时计算梦想完成率
        BigDecimal completionRate;
        try {
            completionRate = calculateDreamCompletionRate(dream.getId());
            log.info("计算梦想[{}]的实时完成率: {}%", dream.getId(), completionRate);
        } catch (Exception e) {
            log.error("计算梦想完成率出错, dreamId: {}", dream.getId(), e);
            completionRate = BigDecimal.ZERO;
        }
        
        // 构建并返回梦想DTO
        DreamDTO dto = DreamDTO.builder()
                .id(dream.getId())
                .userId(dream.getUser().getId())
                .title(dream.getTitle())
                .description(dream.getDescription())
                .category(dream.getCategory())
                .priority(dream.getPriority())
                .status(dream.getStatus())
                .completionRate(completionRate)
                .deadline(dream.getDeadline())
                .expectedDays(dream.getExpectedDays())
                .imageUrl(dream.getImageUrl())
                .isPublic(dream.getIsPublic())
                .createdAt(dream.getCreatedAt())
                .updatedAt(dream.getUpdatedAt())
                .tags(tags)
                .resources(resources)
                .build();
        
        return dto;
    }
    
    /**
     * 计算梦想的实时完成率
     *
     * @param dreamId 梦想ID
     * @return 完成率（百分比）
     */
    private BigDecimal calculateDreamCompletionRate(Long dreamId) {
        // 获取梦想相关的所有任务
        List<Task> tasks = taskRepository.findByDreamId(dreamId);
        
        // 如果没有任务，完成率为0
        if (tasks.isEmpty()) {
            return BigDecimal.ZERO;
        }
        
        // 计算已完成任务的数量
        long completedTasks = tasks.stream()
                .filter(task -> task.getStatus() == 2)  // 状态为2表示已完成
                .count();
                
        // 计算完成率百分比
        return BigDecimal.valueOf(completedTasks)
                .multiply(BigDecimal.valueOf(100))
                .divide(BigDecimal.valueOf(tasks.size()), 0, RoundingMode.HALF_UP);
    }
} 