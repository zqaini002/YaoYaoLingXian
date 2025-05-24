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
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 梦想数据传输对象
 *
 * @author DreamPlanner
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "梦想信息")
public class DreamDTO {

    @Schema(description = "梦想ID")
    private Long id;

    @Schema(description = "用户ID")
    @NotNull(message = "用户ID不能为空")
    private Long userId;

    @Schema(description = "梦想标题")
    @NotBlank(message = "梦想标题不能为空")
    private String title;

    @Schema(description = "梦想描述")
    private String description;

    @Schema(description = "分类")
    private String category;

    @Schema(description = "优先级：1-最高，5-最低")
    @Min(value = 1, message = "优先级最小值为1")
    @Max(value = 5, message = "优先级最大值为5")
    private Integer priority;

    @Schema(description = "状态：0-放弃，1-进行中，2-已完成")
    @NotNull(message = "状态不能为空")
    private Integer status;

    @Schema(description = "完成率")
    private BigDecimal completionRate;

    @Schema(description = "截止日期")
    private LocalDate deadline;

    @Schema(description = "预计所需天数")
    private Integer expectedDays;

    @Schema(description = "图片URL")
    private String imageUrl;

    @Schema(description = "是否公开：0-私密，1-公开")
    private Integer isPublic;

    @Schema(description = "创建时间")
    private LocalDateTime createdAt;

    @Schema(description = "更新时间")
    private LocalDateTime updatedAt;

    @Schema(description = "任务列表")
    private List<TaskDTO> tasks;

    @Schema(description = "推荐资源")
    private List<ResourceDTO> resources;

    @Schema(description = "标签列表")
    private List<String> tags;
} 