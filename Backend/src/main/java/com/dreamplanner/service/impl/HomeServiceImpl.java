package com.dreamplanner.service.impl;

import com.dreamplanner.dto.*;
import com.dreamplanner.entity.User;
import com.dreamplanner.repository.UserRepository;
import com.dreamplanner.service.DreamService;
import com.dreamplanner.service.HomeService;
import com.dreamplanner.service.TaskService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * 首页服务实现类
 *
 * @author DreamPlanner
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class HomeServiceImpl implements HomeService {

    private final UserRepository userRepository;
    private final DreamService dreamService;
    private final TaskService taskService;

    /**
     * 获取首页数据
     *
     * @param userId 用户ID
     * @return 首页数据DTO
     */
    @Override
    @Transactional(readOnly = true)
    public HomePageDTO getHomePageData(Long userId) {
        log.info("获取首页数据, userId: {}", userId);

        // 创建默认用户信息，避免因数据库问题导致的空指针异常
        String username = "用户" + userId;
        String nickname = "用户" + userId;
        String avatar = "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde";
        String signature = "每天进步一点点";

        // 获取用户信息 - 使用try-catch避免因表不存在导致的异常
        try {
            // 改用findById替代getReferenceById，确保实际查询数据库
            Optional<User> userOpt = userRepository.findById(userId);
            if (userOpt.isPresent()) {
                User user = userOpt.get();
                username = user.getUsername();
                nickname = user.getNickname() != null ? user.getNickname() : username;
                avatar = user.getAvatar() != null ? user.getAvatar() : avatar;
                signature = user.getSignature() != null ? user.getSignature() : signature;
                
                log.info("成功获取用户信息: username={}, nickname={}, signature={}", username, nickname, signature);
            } else {
                log.warn("用户不存在，使用默认值, userId: {}", userId);
            }
        } catch (Exception e) {
            log.warn("获取用户信息失败，使用默认值, userId: {}, error: {}", userId, e.getMessage());
        }

        // 获取梦想统计
        DreamStatsDTO dreamStats = null;
        try {
            dreamStats = dreamService.getUserDreamStats(userId);
        } catch (Exception e) {
            log.warn("获取梦想统计失败，使用默认值, userId: {}, error: {}", userId, e.getMessage());
            dreamStats = DreamStatsDTO.builder()
                .userId(userId)
                .totalDreams(0L)
                .completedDreams(0L)
                .inProgressDreams(0L)
                .abandonedDreams(0L)
                .dreamCompletionRate(BigDecimal.ZERO)
                .totalTasks(0L)
                .completedTasks(0L)
                .taskCompletionRate(BigDecimal.ZERO)
                .build();
        }

        // 获取今日任务（最多5条）
        PageResponseDTO<TaskDTO> todayTasks;
        try {
            Page<TaskDTO> todayTasksPage = taskService.getTodayTasks(userId, PageRequest.of(0, 5));
            todayTasks = convertToPageResponseDTO(todayTasksPage);
        } catch (Exception e) {
            log.warn("获取今日任务失败，使用默认值, userId: {}, error: {}", userId, e.getMessage());
            todayTasks = PageResponseDTO.<TaskDTO>builder()
                .content(new ArrayList<>())
                .totalElements(0L)
                .totalPages(0)
                .size(0)
                .number(0)
                .first(true)
                .last(true)
                .build();
        }
        
        // 获取即将到期的任务（未来7天内，最多5条）
        PageResponseDTO<TaskDTO> upcomingTasks;
        try {
            Page<TaskDTO> upcomingTasksPage = taskService.getUpcomingTasks(userId, 7, PageRequest.of(0, 5));
            upcomingTasks = convertToPageResponseDTO(upcomingTasksPage);
        } catch (Exception e) {
            log.warn("获取即将到期任务失败，使用默认值, userId: {}, error: {}", userId, e.getMessage());
            upcomingTasks = PageResponseDTO.<TaskDTO>builder()
                .content(new ArrayList<>())
                .totalElements(0L)
                .totalPages(0)
                .size(0)
                .number(0)
                .first(true)
                .last(true)
                .build();
        }

        // 获取最近更新的梦想（最多3条）
        List<DreamDTO> recentDreams = new ArrayList<>();
        try {
            List<DreamDTO> allDreams = dreamService.getDreamsByUserId(userId);
            if (allDreams != null && !allDreams.isEmpty()) {
                recentDreams = allDreams.stream()
                    .filter(d -> d.getUpdatedAt() != null)
                    .sorted((d1, d2) -> {
                        // 防止空指针异常
                        if (d1.getUpdatedAt() == null) return 1;
                        if (d2.getUpdatedAt() == null) return -1;
                        return d2.getUpdatedAt().compareTo(d1.getUpdatedAt());
                    })
                    .limit(3)
                    .collect(Collectors.toList());
            }
        } catch (Exception e) {
            log.error("获取最近更新的梦想出错: {}", e.getMessage());
        }

        // 构建首页DTO
        return HomePageDTO.builder()
                .userId(userId)
                .username(username)
                .nickname(nickname)
                .avatar(avatar)
                .signature(signature)  // 添加用户签名
                .dreamStats(dreamStats)
                .todayTasks(todayTasks)
                .upcomingTasks(upcomingTasks)
                .recentDreams(recentDreams)
                .recommendedResources(Collections.emptyList()) // 暂无推荐资源逻辑
                .build();
    }
    
    /**
     * 将Spring Data JPA的Page对象转换为自定义PageResponseDTO
     *
     * @param page Spring Data JPA的Page对象
     * @return 自定义PageResponseDTO对象
     */
    private <T> PageResponseDTO<T> convertToPageResponseDTO(Page<T> page) {
        if (page == null) {
            return PageResponseDTO.<T>builder()
                    .content(new ArrayList<>())
                    .totalElements(0L)
                    .totalPages(0)
                    .size(0)
                    .number(0)
                    .first(true)
                    .last(true)
                    .build();
        }
        
        return PageResponseDTO.<T>builder()
                .content(page.getContent())
                .totalElements(page.getTotalElements())
                .totalPages(page.getTotalPages())
                .size(page.getSize())
                .number(page.getNumber())
                .first(page.isFirst())
                .last(page.isLast())
                .build();
    }
} 