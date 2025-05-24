package com.dreamplanner.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 首页数据传输对象
 *
 * @author DreamPlanner
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "首页信息")
public class HomePageDTO {

    @Schema(description = "用户ID")
    private Long userId;
    
    @Schema(description = "用户名")
    private String username;
    
    @Schema(description = "用户昵称")
    private String nickname;
    
    @Schema(description = "用户头像")
    private String avatar;
    
    @Schema(description = "用户签名")
    private String signature;
    
    @Schema(description = "梦想统计")
    private DreamStatsDTO dreamStats;
    
    @Schema(description = "今日任务")
    private PageResponseDTO<TaskDTO> todayTasks;
    
    @Schema(description = "即将到期的任务")
    private PageResponseDTO<TaskDTO> upcomingTasks;
    
    @Schema(description = "推荐资源")
    private List<ResourceDTO> recommendedResources;
    
    @Schema(description = "最近更新的梦想")
    private List<DreamDTO> recentDreams;
} 