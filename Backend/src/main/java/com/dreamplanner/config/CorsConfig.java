package com.dreamplanner.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

/**
 * CORS配置，允许跨域请求
 */
@Configuration
public class CorsConfig {

    @Bean
    public CorsFilter corsFilter() {
        CorsConfiguration config = new CorsConfiguration();
        
        // 允许来自这些域名的请求
        config.addAllowedOrigin("http://localhost:8080");
        config.addAllowedOrigin("capacitor://localhost");
        config.addAllowedOrigin("http://localhost");
        config.addAllowedOrigin("http://127.0.0.1");
        config.addAllowedOrigin("http://127.0.0.1:8080");
        config.addAllowedOrigin("http://10.0.2.2:8080"); // 用于Android模拟器
        config.addAllowedOrigin("http://192.168.31.75:8080"); // 用于真机测试
        // 注意：不能同时使用通配符和setAllowCredentials(true)
        // config.addAllowedOrigin("*"); 
        
        // 允许跨越发送cookie (由于使用了特定的域名而不是通配符，所以可以启用)
        config.setAllowCredentials(true);
        
        // 放行全部原始头信息
        config.addAllowedHeader("*");
        
        // 允许所有请求方法跨域调用
        config.addAllowedMethod("*");
        
        // 增加返回的头信息
        config.addExposedHeader("Access-Control-Allow-Origin");
        config.addExposedHeader("Access-Control-Allow-Headers");
        config.addExposedHeader("Access-Control-Allow-Methods");
        config.addExposedHeader("Access-Control-Max-Age");
        config.addExposedHeader("Access-Control-Allow-Credentials");
        
        // 设置预检请求的缓存时间
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        
        return new CorsFilter(source);
    }
} 