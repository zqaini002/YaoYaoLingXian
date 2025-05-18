package com.dreamplanner.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * 业务异常
 *
 * @author DreamPlanner
 */
@ResponseStatus(HttpStatus.BAD_REQUEST)
public class BusinessException extends RuntimeException {

    private final HttpStatus status;

    public BusinessException(String message) {
        super(message);
        this.status = HttpStatus.BAD_REQUEST;
    }

    public BusinessException(String message, HttpStatus status) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }
} 