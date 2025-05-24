package com.dreamplanner.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 通用API响应对象
 * 与前端ApiResponse接口对应
 *
 * @author DreamPlanner
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "API响应")
public class ApiResponseDTO<T> {
    
    @Schema(description = "响应码")
    private Integer code;
    
    @Schema(description = "响应消息")
    private String message;
    
    @Schema(description = "响应数据")
    private T data;
    
    /**
     * 创建成功响应
     *
     * @param data 响应数据
     * @return API响应
     */
    public static <T> ApiResponseDTO<T> success(T data) {
        return ApiResponseDTO.<T>builder()
                .code(200)
                .message("操作成功")
                .data(data)
                .build();
    }
    
    /**
     * 创建失败响应
     *
     * @param message 错误消息
     * @return API响应
     */
    public static <T> ApiResponseDTO<T> error(String message) {
        return ApiResponseDTO.<T>builder()
                .code(500)
                .message(message)
                .build();
    }
    
    /**
     * 创建失败响应
     *
     * @param code 错误码
     * @param message 错误消息
     * @return API响应
     */
    public static <T> ApiResponseDTO<T> error(Integer code, String message) {
        return ApiResponseDTO.<T>builder()
                .code(code)
                .message(message)
                .build();
    }
}