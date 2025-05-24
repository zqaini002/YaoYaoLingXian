package com.dreamplanner.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 任务数据传输对象
 *
 * @author DreamPlanner
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "任务信息")
public class TaskDTO {

    @Schema(description = "任务ID")
    private Long id;

    @Schema(description = "梦想ID")
    @NotNull(message = "梦想ID不能为空")
    private Long dreamId;

    @Schema(description = "用户ID")
    @NotNull(message = "用户ID不能为空")
    private Long userId;

    @Schema(description = "任务标题")
    @NotBlank(message = "任务标题不能为空")
    private String title;

    @Schema(description = "任务描述")
    private String description;

    @Schema(description = "状态：0-待开始，1-进行中，2-已完成，3-已延期")
    @NotNull(message = "状态不能为空")
    private Integer status;

    @Schema(description = "优先级：1-最高，5-最低")
    @Min(value = 1, message = "优先级最小值为1")
    @Max(value = 5, message = "优先级最大值为5")
    private Integer priority;

    @Schema(description = "开始日期")
    private LocalDate startDate;

    @Schema(description = "截止日期")
    private LocalDate dueDate;

    @Schema(description = "完成时间")
    private LocalDateTime completedAt;

    @Schema(description = "提醒时间")
    private LocalDateTime reminderTime;

    @Schema(description = "父任务ID")
    private Long parentTaskId;

    @Schema(description = "创建时间")
    private LocalDateTime createdAt;

    @Schema(description = "更新时间")
    private LocalDateTime updatedAt;

    @Schema(description = "子任务列表")
    private List<TaskDTO> childTasks;
    
    @Schema(description = "关联的梦想标题", hidden = true)
    private String dreamTitle;
    
    @Schema(description = "是否为今日任务", hidden = true)
    private Boolean isTodayTask;
    
    @Schema(description = "是否已过期", hidden = true)
    private Boolean isOverdue;
    
    @Schema(description = "是否为即将到期的任务", hidden = true)
    private Boolean isUpcomingTask;
} 