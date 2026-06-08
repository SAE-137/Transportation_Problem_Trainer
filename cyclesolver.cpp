#include "cyclesolver.h"

QVector<QVector<QString>> CycleSolver::makeStringMatrix(int rows, int cols) const
{
    return QVector<QVector<QString>>(rows, QVector<QString>(cols, ""));
}

bool CycleSolver::containsCell(const QVector<QPair<int, int>>& path, int r, int c) const
{
    for (const auto& cell : path) {
        if (cell.first == r && cell.second == c)
            return true;
    }
    return false;
}

bool CycleSolver::dfs(const QVector<QVector<bool>>& allowed,
                      int startRow,
                      int startCol,
                      QVector<QPair<int, int>>& path,
                      bool moveAlongRow,
                      QVector<QPair<int, int>>& outPath) const
{
    const int rows = allowed.size();
    const int cols = allowed[0].size();

    const int curRow = path.last().first;
    const int curCol = path.last().second;

    if (moveAlongRow) {
        for (int c = 0; c < cols; ++c) {
            if (c == curCol)
                continue;
            if (!allowed[curRow][c])
                continue;

            if (curRow == startRow && c == startCol) {
                if (path.size() >= 4) {
                    outPath = path;
                    outPath.push_back({startRow, startCol});
                    return true;
                }
                continue;
            }

            if (containsCell(path, curRow, c))
                continue;

            path.push_back({curRow, c});
            if (dfs(allowed, startRow, startCol, path, !moveAlongRow, outPath))
                return true;
            path.pop_back();
        }
    } else {
        for (int r = 0; r < rows; ++r) {
            if (r == curRow)
                continue;
            if (!allowed[r][curCol])
                continue;

            if (r == startRow && curCol == startCol) {
                if (path.size() >= 4) {
                    outPath = path;
                    outPath.push_back({startRow, startCol});
                    return true;
                }
                continue;
            }

            if (containsCell(path, r, curCol))
                continue;

            path.push_back({r, curCol});
            if (dfs(allowed, startRow, startCol, path, !moveAlongRow, outPath))
                return true;
            path.pop_back();
        }
    }

    return false;
}

bool CycleSolver::findCycle(const QVector<QVector<bool>>& allowed,
                            int startRow,
                            int startCol,
                            QVector<QPair<int, int>>& outPath) const
{
    QVector<QPair<int, int>> path;
    path.push_back({startRow, startCol});

    if (dfs(allowed, startRow, startCol, path, true, outPath))
        return true;

    path.clear();
    path.push_back({startRow, startCol});

    if (dfs(allowed, startRow, startCol, path, false, outPath))
        return true;

    return false;
}

CycleResult CycleSolver::solve(const TransportProblemState& source,
                               const QVector<QVector<QString>>& loadMatrix,
                               int enterRow,
                               int enterCol) const
{
    CycleResult result;

    const int rows = source.rows();
    const int cols = source.cols();

    if (rows <= 0 || cols <= 0) {
        result.message = "Ошибка: пустая задача для построения цикла.";
        return result;
    }

    if (enterRow < 0 || enterRow >= rows || enterCol < 0 || enterCol >= cols) {
        result.message = "Ошибка: неверная начальная клетка для цикла.";
        return result;
    }

    if (loadMatrix.size() != rows) {
        result.message = "Ошибка: матрица перевозок имеет неверное число строк.";
        return result;
    }

    for (const auto& row : loadMatrix) {
        if (row.size() != cols) {
            result.message = "Ошибка: матрица перевозок имеет неверное число столбцов.";
            return result;
        }
    }

    const QVector<QVector<int>> costs = source.costMatrix();
    const QVector<int> supply = source.supply();
    const QVector<int> demand = source.demand();

    QVector<QVector<bool>> allowed(rows, QVector<bool>(cols, false));

    for (int r = 0; r < rows; ++r) {
        for (int c = 0; c < cols; ++c) {
            const QString x = loadMatrix[r][c].trimmed();
            if (!x.isEmpty())
                allowed[r][c] = true;
        }
    }

    // добавляем начальную клетку, которая войдёт в базис
    allowed[enterRow][enterCol] = true;

    {
        CycleStep step;
        step.title = "Начальная клетка цикла";
        step.description = "Из этапа проверки оптимальности получена клетка, которая должна войти в базис.";
        step.calculationText =
            QString("Начальная клетка цикла: (B%1, A%2).\n"
                    "Помечаем её символом r и начинаем строить замкнутый цикл пересчёта.")
                .arg(enterRow + 1)
                .arg(enterCol + 1);

        step.costMatrix = costs;
        step.supply = supply;
        step.demand = demand;
        step.loadMatrix = loadMatrix;
        step.markMatrix = makeStringMatrix(rows, cols);
        step.markMatrix[enterRow][enterCol] = "r";
        step.selectedRow = enterRow;
        step.selectedCol = enterCol;

        result.steps.push_back(step);
    }

    QVector<QPair<int, int>> cyclePath;
    if (!findCycle(allowed, enterRow, enterCol, cyclePath)) {
        result.message = "Ошибка: не удалось построить цикл пересчёта.";
        return result;
    }

    QVector<QVector<QString>> cycleMarks = makeStringMatrix(rows, cols);
    cycleMarks[enterRow][enterCol] = "r";

    QString pathText = "Найден цикл:\n";
    QString signText = "Расставляем знаки:\n";

    QVector<QPair<int, int>> minusCells;

    for (int i = 0; i < cyclePath.size(); ++i) {
        const int r = cyclePath[i].first;
        const int c = cyclePath[i].second;

        pathText += QString("(B%1, A%2)").arg(r + 1).arg(c + 1);
        if (i + 1 < cyclePath.size())
            pathText += " -> ";
    }

    for (int i = 1; i < cyclePath.size() - 1; ++i) {
        const int r = cyclePath[i].first;
        const int c = cyclePath[i].second;

        if (i % 2 == 1) {
            cycleMarks[r][c] = "-";
            minusCells.push_back({r, c});
            signText += QString("(B%1, A%2) : -\n").arg(r + 1).arg(c + 1);
        } else {
            cycleMarks[r][c] = "+";
            signText += QString("(B%1, A%2) : +\n").arg(r + 1).arg(c + 1);
        }
    }

    QString minusText = "Клетки со знаком '-' участвуют в выборе r на следующем этапе:\n";
    for (const auto& cell : minusCells) {
        minusText += QString("(B%1, A%2)\n").arg(cell.first + 1).arg(cell.second + 1);
    }

    {
        CycleStep step;
        step.title = "Цикл пересчёта построен";
        step.description = "Построен замкнутый цикл, проходящий через начальную клетку и базисные клетки.";
        step.calculationText = pathText + "\n\n" + signText + "\n" + minusText;

        step.costMatrix = costs;
        step.supply = supply;
        step.demand = demand;
        step.loadMatrix = loadMatrix;
        step.markMatrix = cycleMarks;
        step.selectedRow = enterRow;
        step.selectedCol = enterCol;

        result.steps.push_back(step);
    }

    result.valid = true;
    result.message = "Цикл пересчёта построен.";
    result.cyclePath = cyclePath;
    result.minusCells = minusCells;

    return result;
}
