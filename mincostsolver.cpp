#include "mincostsolver.h"

#include <limits>
#include <queue>
#include <utility>

bool MinCostSolver::hasOpenCells(const QVector<int>& supply, const QVector<int>& demand) const
{
    bool hasSupply = false;
    for (int x : supply) {
        if (x > 0) {
            hasSupply = true;
            break;
        }
    }

    bool hasDemand = false;
    for (int x : demand) {
        if (x > 0) {
            hasDemand = true;
            break;
        }
    }

    return hasSupply && hasDemand;
}

QVector<QVector<QString>> MinCostSolver::makeStringMatrix(int rows, int cols) const
{
    return QVector<QVector<QString>>(rows, QVector<QString>(cols, ""));
}

bool MinCostSolver::isBasisCell(const QVector<QVector<QString>>& loadMatrix, int row, int col) const
{
    if (row < 0 || row >= loadMatrix.size())
        return false;

    if (loadMatrix.isEmpty() || col < 0 || col >= loadMatrix[0].size())
        return false;

    return !loadMatrix[row][col].trimmed().isEmpty();
}

int MinCostSolver::countBasisCells(const QVector<QVector<QString>>& loadMatrix) const
{
    int count = 0;

    for (int r = 0; r < loadMatrix.size(); ++r) {
        for (int c = 0; c < loadMatrix[r].size(); ++c) {
            if (isBasisCell(loadMatrix, r, c))
                ++count;
        }
    }

    return count;
}

bool MinCostSolver::createsCycle(const QVector<QVector<QString>>& loadMatrix, int addRow, int addCol) const
{
    const int rows = loadMatrix.size();
    if (rows == 0)
        return false;

    const int cols = loadMatrix[0].size();

    QVector<bool> visitedRows(rows, false);
    QVector<bool> visitedCols(cols, false);

    std::queue<std::pair<bool, int>> q;
    visitedRows[addRow] = true;
    q.push({true, addRow});

    while (!q.empty()) {
        const auto [isRowNode, index] = q.front();
        q.pop();

        if (isRowNode) {
            const int r = index;
            for (int c = 0; c < cols; ++c) {
                if (!isBasisCell(loadMatrix, r, c) || visitedCols[c])
                    continue;

                if (c == addCol)
                    return true;

                visitedCols[c] = true;
                q.push({false, c});
            }
        } else {
            const int c = index;
            for (int r = 0; r < rows; ++r) {
                if (!isBasisCell(loadMatrix, r, c) || visitedRows[r])
                    continue;

                visitedRows[r] = true;
                q.push({true, r});
            }
        }
    }

    return false;
}

bool MinCostSolver::chooseZeroBasisCell(const QVector<QVector<QString>>& loadMatrix,
                                        const QVector<int>& supplyLeft,
                                        const QVector<int>& demandLeft,
                                        int chosenRow,
                                        int chosenCol,
                                        int& zeroRow,
                                        int& zeroCol) const
{
    const int rows = loadMatrix.size();
    const int cols = rows > 0 ? loadMatrix[0].size() : 0;

    auto tryPick = [&](int r, int c) -> bool {
        if (r < 0 || r >= rows || c < 0 || c >= cols)
            return false;

        if (r == chosenRow && c == chosenCol)
            return false;

        if (isBasisCell(loadMatrix, r, c))
            return false;

        if (createsCycle(loadMatrix, r, c))
            return false;

        zeroRow = r;
        zeroCol = c;
        return true;
    };

    // Предпочитаем оставить активной строку выбранной клетки,
    // как это делается в методичке: добавляем нулевую базисную клетку
    // в той же строке и в ещё не закрытом столбце.
    for (int c = 0; c < cols; ++c) {
        if (c == chosenCol || demandLeft[c] <= 0)
            continue;

        if (tryPick(chosenRow, c))
            return true;
    }

    // Если это невозможно, оставляем активным столбец выбранной клетки.
    for (int r = 0; r < rows; ++r) {
        if (r == chosenRow || supplyLeft[r] <= 0)
            continue;

        if (tryPick(r, chosenCol))
            return true;
    }

    // Запасной вариант: ищем любую пустую клетку, которая не создаёт цикл
    // и принадлежит ещё не завершённой части таблицы.
    for (int r = 0; r < rows; ++r) {
        const bool rowRelevant = (r == chosenRow) || (supplyLeft[r] > 0);
        if (!rowRelevant)
            continue;

        for (int c = 0; c < cols; ++c) {
            const bool colRelevant = (c == chosenCol) || (demandLeft[c] > 0);
            if (!colRelevant)
                continue;

            if (tryPick(r, c))
                return true;
        }
    }

    return false;
}

MinCostResult MinCostSolver::solve(const TransportProblemState& source) const
{
    MinCostResult result;

    if (source.rows() <= 0 || source.cols() <= 0) {
        result.message = "Ошибка: пустая задача для метода минимального тарифа.";
        return result;
    }

    const QVector<QVector<int>> costs = source.costMatrix();
    QVector<int> supplyLeft = source.supply();
    QVector<int> demandLeft = source.demand();

    const int rows = source.rows();
    const int cols = source.cols();

    QVector<QVector<QString>> loadMatrix = makeStringMatrix(rows, cols);
    QVector<QVector<QString>> markMatrix = makeStringMatrix(rows, cols);

    while (hasOpenCells(supplyLeft, demandLeft)) {
        int minCost = std::numeric_limits<int>::max();
        QVector<QPair<int, int>> candidates;

        for (int r = 0; r < rows; ++r) {
            if (supplyLeft[r] <= 0)
                continue;

            for (int c = 0; c < cols; ++c) {
                if (demandLeft[c] <= 0)
                    continue;

                const int currentCost = costs[r][c];

                if (currentCost < minCost) {
                    minCost = currentCost;
                    candidates.clear();
                    candidates.push_back({r, c});
                } else if (currentCost == minCost) {
                    candidates.push_back({r, c});
                }
            }
        }

        if (candidates.isEmpty()) {
            result.message = "Ошибка: не удалось найти допустимую клетку.";
            return result;
        }

        const int chosenRow = candidates[0].first;
        const int chosenCol = candidates[0].second;

        markMatrix = makeStringMatrix(rows, cols);
        for (const auto& cell : candidates)
            markMatrix[cell.first][cell.second] = "min";

        {
            MinCostStep step;
            step.title = "Поиск минимального тарифа";

            QString candidateText;
            for (int i = 0; i < candidates.size(); ++i) {
                const int r = candidates[i].first + 1;
                const int c = candidates[i].second + 1;
                candidateText += QString("(B%1, A%2)").arg(r).arg(c);
                if (i + 1 < candidates.size())
                    candidateText += ", ";
            }

            step.description =
                QString("Среди незакрытых строк и столбцов найден минимальный тариф %1. "
                        "Минимальные клетки: %2. "
                        "Для текущего шага выбираем первую по порядку клетку (B%3, A%4).")
                    .arg(minCost)
                    .arg(candidateText)
                    .arg(chosenRow + 1)
                    .arg(chosenCol + 1);

            step.costMatrix = costs;
            step.supply = supplyLeft;
            step.demand = demandLeft;
            step.loadMatrix = loadMatrix;
            step.markMatrix = markMatrix;
            step.selectedRow = chosenRow;
            step.selectedCol = chosenCol;

            result.steps.push_back(step);
        }

        const int oldSupply = supplyLeft[chosenRow];
        const int oldDemand = demandLeft[chosenCol];
        const int x = qMin(oldSupply, oldDemand);

        loadMatrix[chosenRow][chosenCol] = QString::number(x);

        supplyLeft[chosenRow] -= x;
        demandLeft[chosenCol] -= x;

        const bool rowClosed = (supplyLeft[chosenRow] == 0);
        const bool colClosed = (demandLeft[chosenCol] == 0);
        const bool simultaneousExhaustion = rowClosed && colClosed;

        markMatrix = makeStringMatrix(rows, cols);
        markMatrix[chosenRow][chosenCol] = "x";

        {
            MinCostStep step;
            step.title = QString("Заполнение клетки (B%1, A%2)")
                             .arg(chosenRow + 1)
                             .arg(chosenCol + 1);

            step.description =
                QString("В выбранную клетку записываем x = min(%1, %2) = %3. "
                        "Новый остаток по строке B%4: %5. "
                        "Новый остаток по столбцу A%6: %7.")
                    .arg(oldSupply)
                    .arg(oldDemand)
                    .arg(x)
                    .arg(chosenRow + 1)
                    .arg(supplyLeft[chosenRow])
                    .arg(chosenCol + 1)
                    .arg(demandLeft[chosenCol]);

            if (simultaneousExhaustion) {
                step.description +=
                    " Одновременно исчерпаны и запас, и потребность. "
                    "Чтобы не получить вырожденный план, далее будет добавлена нулевая базисная клетка.";
            } else if (rowClosed) {
                step.description += QString(" Строка B%1 закрывается.").arg(chosenRow + 1);
            } else if (colClosed) {
                step.description += QString(" Столбец A%1 закрывается.").arg(chosenCol + 1);
            }

            step.costMatrix = costs;
            step.supply = supplyLeft;
            step.demand = demandLeft;
            step.loadMatrix = loadMatrix;
            step.markMatrix = markMatrix;
            step.selectedRow = chosenRow;
            step.selectedCol = chosenCol;

            result.steps.push_back(step);
        }

        if (simultaneousExhaustion && hasOpenCells(supplyLeft, demandLeft)) {
            int zeroRow = -1;
            int zeroCol = -1;

            if (!chooseZeroBasisCell(loadMatrix,
                                     supplyLeft,
                                     demandLeft,
                                     chosenRow,
                                     chosenCol,
                                     zeroRow,
                                     zeroCol)) {
                result.message =
                    "Ошибка: возникла вырожденность, но не удалось добавить нулевую базисную клетку.";
                return result;
            }

            loadMatrix[zeroRow][zeroCol] = "0";

            markMatrix = makeStringMatrix(rows, cols);
            markMatrix[zeroRow][zeroCol] = "0";

            MinCostStep step;
            step.title = "Устранение вырожденности";
            step.description =
                QString("После одновременного закрытия строки и столбца добавляем нулевую базисную "
                        "клетку (B%1, A%2). Она не меняет запасы, потребности и стоимость, "
                        "но сохраняет нужное число базисных клеток для метода потенциалов.")
                    .arg(zeroRow + 1)
                    .arg(zeroCol + 1);

            step.costMatrix = costs;
            step.supply = supplyLeft;
            step.demand = demandLeft;
            step.loadMatrix = loadMatrix;
            step.markMatrix = markMatrix;
            step.selectedRow = zeroRow;
            step.selectedCol = zeroCol;

            result.steps.push_back(step);
        }
    }

    {
        const int basisCount = countBasisCells(loadMatrix);
        const int requiredBasisCount = rows + cols - 1;

        MinCostStep step;
        step.title = "Опорный план построен";
        step.description =
            QString("Все запасы и потребности распределены. Построение опорного плана методом "
                    "минимального тарифа завершено. Число базисных клеток: %1 из %2.")
                .arg(basisCount)
                .arg(requiredBasisCount);
        step.costMatrix = costs;
        step.supply = supplyLeft;
        step.demand = demandLeft;
        step.loadMatrix = loadMatrix;
        step.markMatrix = makeStringMatrix(rows, cols);
        step.selectedRow = -1;
        step.selectedCol = -1;
        result.steps.push_back(step);
    }

    result.valid = true;
    result.message = "Опорный план методом минимального тарифа построен.";
    result.finalLoadMatrix = loadMatrix;
    return result;
}
