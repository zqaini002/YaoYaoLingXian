package com.dreamplanner.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web配置类
 * 用于配置CORS跨域访问、静态资源映射等
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    /**
     * 配置跨域访问
     */
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOriginPatterns("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }

    /**
     * 配置静态资源映射
     * 将请求路径/uploads/映射到文件系统的上传目录
     */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 获取操作系统名称
        String os = System.getProperty("os.name");
        
        // 根据不同操作系统配置上传文件保存的路径
        String uploadPath;
        if (os.toLowerCase().startsWith("win")) {
            // Windows系统
            uploadPath = "file:D:/dreamplanner/uploads/";
        } else {
            // Linux或Mac系统
            uploadPath = "file:/home/dreamplanner/uploads/";
        }
        
        // 添加资源处理器，将web请求映射到本地文件系统
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations(uploadPath);
        
        // 默认静态资源处理器
        registry.addResourceHandler("/static/**")
                .addResourceLocations("classpath:/static/");
    }
} 