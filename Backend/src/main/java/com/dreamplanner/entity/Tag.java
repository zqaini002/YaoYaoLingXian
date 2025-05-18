package com.dreamplanner.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

/**
 * 标签实体类
 *
 * @author DreamPlanner
 */
@Entity
@Table(name = "tag")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(of = "id")
@ToString(exclude = {"dreams"})
public class Tag implements Serializable {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "name", nullable = false, unique = true, length = 50)
    private String name;

    @Column(name = "category", length = 50)
    private String category;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @ManyToMany(mappedBy = "tags")
    private Set<Dream> dreams = new HashSet<>();

    /**
     * 创建前，设置创建时间
     */
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
} 