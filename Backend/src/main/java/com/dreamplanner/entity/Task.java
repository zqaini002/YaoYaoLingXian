package com.dreamplanner.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

/**
 * 任务实体类
 *
 * @author DreamPlanner
 */
@Entity
@Table(name = "task")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(of = "id")
@ToString(exclude = {"user", "dream", "subtasks", "parentTask"})
public class Task implements Serializable {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "dream_id", nullable = false)
    private Dream dream;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "title", nullable = false, length = 100)
    private String title;

    @Column(name = "description", columnDefinition = "text")
    private String description;

    @Column(name = "status", nullable = false, columnDefinition = "tinyint")
    private Integer status;

    @Column(name = "priority")
    private Integer priority;

    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "due_date")
    private LocalDate dueDate;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "reminder_time")
    private LocalDateTime reminderTime;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_task_id")
    private Task parentTask;

    @OneToMany(mappedBy = "parentTask", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Set<Task> subtasks = new HashSet<>();

    /**
     * 获取子任务列表（childTasks是subtasks的别名）
     * @return 子任务集合
     */
    public Set<Task> getChildTasks() {
        return subtasks;
    }

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    /**
     * 创建前，设置创建时间和更新时间
     */
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = createdAt;
    }

    /**
     * 更新前，设置更新时间
     */
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
} 