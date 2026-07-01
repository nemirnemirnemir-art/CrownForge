from collections import deque
from pathlib import Path

adj = {
    (0, 0): {(0, 1), (1, 0)},
    (0, 1): {(0, 0), (0, 2), (1, 1)},
    (0, 2): {(0, 1), (1, 2)},
    (1, 0): {(0, 0), (1, 1), (2, 0)},
    (1, 1): {(0, 1), (1, 0), (1, 2), (2, 1)},
    (1, 2): {(0, 2), (1, 1), (2, 2)},
    (2, 0): {(1, 0), (2, 1)},
    (2, 1): {(1, 1), (2, 0), (2, 2)},
    (2, 2): {(1, 2), (2, 1)},
}

cells = list(adj.keys())


def rotate(point, r):
    x, y = point
    if r == 0:
        return (x, y)
    if r == 1:
        return (y, 2 - x)
    if r == 2:
        return (2 - x, 2 - y)
    if r == 3:
        return (2 - y, x)
    raise ValueError


def normalize(shape):
    min_x = min(x for x, _ in shape)
    min_y = min(y for _, y in shape)
    return tuple(sorted((x - min_x, y - min_y) for x, y in shape))


def canonical(shape):
    rotations = []
    for r in range(4):
        rotated = [rotate(p, r) for p in shape]
        rotations.append(normalize(rotated))
    return min(rotations)


def is_connected(subset):
    q = deque([subset[0]])
    seen = {subset[0]}
    s = set(subset)
    while q:
        v = q.popleft()
        for nb in adj[v]:
            if nb in s and nb not in seen:
                seen.add(nb)
                q.append(nb)
    return len(seen) == len(subset)


canonical_shapes = set()
count_by_size = {i: 0 for i in range(1, 10)}
unique_by_size = {i: set() for i in range(1, 10)}

for mask in range(1, 1 << 9):
    subset = [cells[i] for i in range(9) if mask >> i & 1]
    if not is_connected(subset):
        continue
    canon = canonical(subset)
    canonical_shapes.add(canon)
    count_by_size[len(subset)] += 1
    unique_by_size[len(subset)].add(canon)


def shape_to_ascii(shape):
    grid = [["." for _ in range(3)] for _ in range(3)]
    for x, y in shape:
        grid[y][x] = "#"
    return "\n".join(" ".join(row) for row in grid)


def build_markdown() -> str:
    lines = [
        "# Gaze Patterns Catalog",
        "",
        "Документ фиксирует **все 46 уникальных связных паттернов** в сетке 3×3, "
        "если считать фигуры одинаковыми при поворотах по часовой стрелке. "
        "Ячейки нумеруются слева направо, сверху вниз (см. схему в Russian_documentaion.md).",
        "",
        "Обозначения:",
        "- `#` — активная клетка (под взглядом).",
        "- `.` — пустая клетка.",
        "",
    ]

    for size in range(1, 10):
        shapes = sorted(unique_by_size[size])
        if not shapes:
            continue
        lines.append(f"## Размер {size} ({len(shapes)} формы)")
        lines.append("")
        for idx, shape in enumerate(shapes, start=1):
            lines.append(f"Форма {size}.{idx}:")
            lines.append("```")
            lines.append(shape_to_ascii(shape))
            lines.append("```")
            lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("*Последнее обновление: 07.02.2026*")
    lines.append("")
    return "\n".join(lines)


def main():
    md = build_markdown()
    target = Path("docs/patterns.md")
    target.write_text(md, encoding="utf-8")


if __name__ == "__main__":
    main()
