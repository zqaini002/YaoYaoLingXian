package com.dreamplanner.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 进度记录数据传输对象
 *
 * @author DreamPlanner
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "进度记录DTO")
public class ProgressDTO {

    @Schema(description = "进度记录ID")
    private Long id;

    @Schema(description = "梦想ID")
    private Long dreamId;

    @Schema(description = "任务ID")
    private Long taskId;

    @Schema(description = "用户ID")
    @NotNull(message = "用户ID不能为空")
    private Long userId;

    @Schema(description = "进度描述")
    @NotBlank(message = "进度描述不能为空")
    private String description;

    @Schema(description = "图片URL，多个用逗号分隔")
    private String images;

    @Schema(description = "创建时间")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createdAt;
} 