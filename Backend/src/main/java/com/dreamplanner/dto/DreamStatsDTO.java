package com.dreamplanner.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * 梦想统计数据传输对象
 *
 * @author DreamPlanner
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "梦想统计信息")
public class DreamStatsDTO {

    @Schema(description = "用户ID")
    private Long userId;
    
    @Schema(description = "梦想总数")
    private Long totalDreams;
    
    @Schema(description = "进行中的梦想数量")
    private Long inProgressDreams;
    
    @Schema(description = "已完成的梦想数量")
    private Long completedDreams;
    
    @Schema(description = "已放弃的梦想数量")
    private Long abandonedDreams;
    
    @Schema(description = "梦想完成率")
    private BigDecimal dreamCompletionRate;
    
    @Schema(description = "任务总数")
    private Long totalTasks;
    
    @Schema(description = "完成的任务数量")
    private Long completedTasks;
    
    @Schema(description = "任务完成率")
    private BigDecimal taskCompletionRate;
} 