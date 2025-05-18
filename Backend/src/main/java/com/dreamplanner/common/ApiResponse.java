package com.dreamplanner.common;

import java.io.Serializable;

/**
 * 统一API响应结果封装
 */
public class ApiResponse implements Serializable {
    private static final long serialVersionUID = 1L;

    private Integer code;
    private String message;
    private Object data;

    public ApiResponse() {
    }

    public ApiResponse(Integer code, String message, Object data) {
        this.code = code;
        this.message = message;
        this.data = data;
    }

    /**
     * 成功响应
     */
    public static ApiResponse success() {
        return new ApiResponse(200, "操作成功", null);
    }

    /**
     * 成功响应带数据
     */
    public static ApiResponse success(Object data) {
        return new ApiResponse(200, "操作成功", data);
    }

    /**
     * 成功响应带消息和数据
     */
    public static ApiResponse success(String message, Object data) {
        return new ApiResponse(200, message, data);
    }

    /**
     * 失败响应
     */
    public static ApiResponse error() {
        return new ApiResponse(500, "操作失败", null);
    }

    /**
     * 失败响应带消息
     */
    public static ApiResponse error(String message) {
        return new ApiResponse(500, message, null);
    }

    /**
     * 失败响应带代码和消息
     */
    public static ApiResponse error(Integer code, String message) {
        return new ApiResponse(code, message, null);
    }

    /**
     * 失败响应带代码、消息和数据
     */
    public static ApiResponse error(Integer code, String message, Object data) {
        return new ApiResponse(code, message, data);
    }

    public Integer getCode() {
        return code;
    }

    public void setCode(Integer code) {
        this.code = code;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public Object getData() {
        return data;
    }

    public void setData(Object data) {
        this.data = data;
    }
} 