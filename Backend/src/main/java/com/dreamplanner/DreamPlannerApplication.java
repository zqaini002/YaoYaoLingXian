package com.dreamplanner;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * 梦想生活规划师应用启动类
 * 
 * @author DreamPlanner
 */
@SpringBootApplication
@EnableScheduling
public class DreamPlannerApplication {

    public static void main(String[] args) {
        SpringApplication.run(DreamPlannerApplication.class, args);
    }
}