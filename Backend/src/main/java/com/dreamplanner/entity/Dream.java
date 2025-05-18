package com.dreamplanner.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

/**
 * 梦想目标实体类
 *
 * @author DreamPlanner
 */
@Entity
@Table(name = "dream")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(of = "id")
@ToString(exclude = {"user", "tasks", "posts", "resources", "tags"})
public class Dream implements Serializable {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "title", nullable = false, length = 100)
    private String title;

    @Column(name = "description", columnDefinition = "text")
    private String description;

    @Column(name = "category", length = 50)
    private String category;

    @Column(name = "priority")
    private Integer priority;

    @Column(name = "status", nullable = false, columnDefinition = "tinyint")
    private Integer status;

    @Column(name = "completion_rate", precision = 5, scale = 2)
    private BigDecimal completionRate;

    @Column(name = "deadline")
    private LocalDate deadline;

    @Column(name = "expected_days")
    private Integer expectedDays;

    @Column(name = "image_url")
    private String imageUrl;

    @Column(name = "is_public", columnDefinition = "tinyint")
    private Integer isPublic;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "dream", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Set<Task> tasks = new HashSet<>();

    @OneToMany(mappedBy = "dream", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Set<Post> posts = new HashSet<>();

    @ManyToMany
    @JoinTable(
        name = "dream_tag",
        joinColumns = @JoinColumn(name = "dream_id"),
        inverseJoinColumns = @JoinColumn(name = "tag_id")
    )
    private Set<Tag> tags = new HashSet<>();

    /**
     * 获取梦想标签（dreamTags是tags的别名）
     * @return 标签集合
     */
    public Set<Tag> getDreamTags() {
        return tags;
    }

    @ManyToMany
    @JoinTable(
        name = "dream_resource",
        joinColumns = @JoinColumn(name = "dream_id"),
        inverseJoinColumns = @JoinColumn(name = "resource_id")
    )
    private Set<Resource> resources = new HashSet<>();

    /**
     * 获取梦想资源（dreamResources是resources的别名）
     * @return 资源集合
     */
    public Set<Resource> getDreamResources() {
        return resources;
    }

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