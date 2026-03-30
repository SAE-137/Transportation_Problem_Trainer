#include "mincostsolver.h"

#include <limits>

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

            if (supplyLeft[chosenRow] == 0 && demandLeft[chosenCol] == 0) {
                step.description += " Одновременно исчерпаны и запас, и потребность.";
            } else if (supplyLeft[chosenRow] == 0) {
                step.description += QString(" Строка B%1 закрывается.").arg(chosenRow + 1);
            } else if (demandLeft[chosenCol] == 0) {
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
    }

    {
        MinCostStep step;
        step.title = "Опорный план построен";
        step.description = "Все запасы и потребности распределены. Построение опорного плана методом минимального тарифа завершено.";
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
