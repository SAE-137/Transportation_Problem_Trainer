#include "potentialsolver.h"

#include <limits>

QVector<QVector<QString>> PotentialSolver::makeStringMatrix(int rows, int cols) const
{
    return QVector<QVector<QString>>(rows, QVector<QString>(cols, ""));
}

PotentialResult PotentialSolver::solve(const TransportProblemState& source,
                                       const QVector<QVector<QString>>& loadMatrix) const
{
    PotentialResult result;

    const int rows = source.rows();
    const int cols = source.cols();

    if (rows <= 0 || cols <= 0) {
        result.message = "Ошибка: пустая задача для метода потенциалов.";
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

    QVector<QVector<bool>> basis(rows, QVector<bool>(cols, false));
    QVector<QVector<QString>> basisMarks = makeStringMatrix(rows, cols);

    int basisCount = 0;
    for (int r = 0; r < rows; ++r) {
        for (int c = 0; c < cols; ++c) {
            const QString x = loadMatrix[r][c].trimmed();
            if (!x.isEmpty()) {
                basis[r][c] = true;
                basisMarks[r][c] = "B";
                ++basisCount;
            }
        }
    }

    if (basisCount < rows + cols - 1) {
        result.message =
            QString("Опорный план вырожден: базисных клеток %1, а должно быть не меньше %2. "
                    "Сначала нужно обработать вырожденность.")
                .arg(basisCount)
                .arg(rows + cols - 1);
        return result;
    }

    {
        PotentialStep step;
        step.title = "Базисные клетки";
        step.description = "Выделяем базисные клетки опорного плана. По ним будут составляться уравнения для потенциалов.";
        step.calculationText =
            QString("Число базисных клеток: %1.\n"
                    "Для невырожденного плана должно быть m + n - 1 = %2.")
                .arg(basisCount)
                .arg(rows + cols - 1);

        step.costMatrix = costs;
        step.supply = supply;
        step.demand = demand;
        step.loadMatrix = loadMatrix;
        step.markMatrix = basisMarks;

        result.steps.push_back(step);
    }

    QVector<int> u(rows, 0);
    QVector<int> v(cols, 0);
    QVector<bool> knownU(rows, false);
    QVector<bool> knownV(cols, false);

    knownU[0] = true;
    u[0] = 0;

    QString equationsText = "Составим уравнения для потенциалов по базисным клеткам:\n";
    for (int r = 0; r < rows; ++r) {
        for (int c = 0; c < cols; ++c) {
            if (basis[r][c]) {
                equationsText += QString("u%1 + v%2 = %3\n")
                .arg(r + 1)
                    .arg(c + 1)
                    .arg(costs[r][c]);
            }
        }
    }

    QString calcText = equationsText;
    calcText += "\nПоложим u1 = 0.\n\nНайдём остальные потенциалы:\n";

    bool progress = true;
    while (progress) {
        progress = false;

        for (int r = 0; r < rows; ++r) {
            for (int c = 0; c < cols; ++c) {
                if (!basis[r][c])
                    continue;

                if (knownU[r] && !knownV[c]) {
                    v[c] = costs[r][c] - u[r];
                    knownV[c] = true;
                    progress = true;

                    calcText += QString("v%1 = c%2%3 - u%2 = %4 - %5 = %6\n")
                                    .arg(c + 1)
                                    .arg(r + 1)
                                    .arg(c + 1)
                                    .arg(costs[r][c])
                                    .arg(u[r])
                                    .arg(v[c]);
                } else if (!knownU[r] && knownV[c]) {
                    u[r] = costs[r][c] - v[c];
                    knownU[r] = true;
                    progress = true;

                    calcText += QString("u%1 = c%1%2 - v%2 = %3 - %4 = %5\n")
                                    .arg(r + 1)
                                    .arg(c + 1)
                                    .arg(costs[r][c])
                                    .arg(v[c])
                                    .arg(u[r]);
                }
            }
        }
    }

    for (int r = 0; r < rows; ++r) {
        if (!knownU[r]) {
            result.message = "Не удалось вычислить все потенциалы u. План, вероятно, вырожденный.";
            return result;
        }
    }

    for (int c = 0; c < cols; ++c) {
        if (!knownV[c]) {
            result.message = "Не удалось вычислить все потенциалы v. План, вероятно, вырожденный.";
            return result;
        }
    }

    calcText += "\nИтоговые потенциалы:\n";
    for (int r = 0; r < rows; ++r)
        calcText += QString("u%1 = %2\n").arg(r + 1).arg(u[r]);

    for (int c = 0; c < cols; ++c)
        calcText += QString("v%1 = %2\n").arg(c + 1).arg(v[c]);

    {
        PotentialStep step;
        step.title = "Вычисление потенциалов";
        step.description = "По базисным клеткам восстанавливаем все потенциалы.";
        step.calculationText = calcText;

        step.costMatrix = costs;
        step.supply = supply;
        step.demand = demand;
        step.loadMatrix = loadMatrix;
        step.markMatrix = basisMarks;

        result.steps.push_back(step);
    }

    int minDelta = std::numeric_limits<int>::max();
    int minRow = -1;
    int minCol = -1;

    QString deltaText = "Вычислим оценки для небазисных клеток:\n";
    bool hasNonBasis = false;

    for (int r = 0; r < rows; ++r) {
        for (int c = 0; c < cols; ++c) {
            if (basis[r][c])
                continue;

            hasNonBasis = true;
            const int delta = costs[r][c] - u[r] - v[c];

            deltaText += QString("Δ%1%2 = c%1%2 - u%1 - v%2 = %3 - (%4) - (%5) = %6\n")
                             .arg(r + 1)
                             .arg(c + 1)
                             .arg(costs[r][c])
                             .arg(u[r])
                             .arg(v[c])
                             .arg(delta);

            if (delta < minDelta) {
                minDelta = delta;
                minRow = r;
                minCol = c;
            }
        }
    }

    if (!hasNonBasis) {
        result.valid = true;
        result.optimal = true;
        result.message = "Проверка оптимальности завершена: небазисных клеток нет.";
        return result;
    }

    if (minDelta >= 0) {
        deltaText += "\nВсе оценки неотрицательны, значит план оптимален.";

        PotentialStep step;
        step.title = "Проверка оптимальности";
        step.description = "Текущий план оптимален.";
        step.calculationText = deltaText;

        step.costMatrix = costs;
        step.supply = supply;
        step.demand = demand;
        step.loadMatrix = loadMatrix;
        step.markMatrix = basisMarks;

        result.steps.push_back(step);

        result.valid = true;
        result.optimal = true;
        result.message = "Проверка оптимальности завершена: план оптимален.";
        return result;
    }

    deltaText += QString("\nМинимальная отрицательная оценка: Δ%1%2 = %3.\n"
                         "Следовательно, план не оптимален.\n"
                         "В базис должна войти клетка (B%1, A%2).")
                     .arg(minRow + 1)
                     .arg(minCol + 1)
                     .arg(minDelta);

    PotentialStep step;
    step.title = "Проверка оптимальности";
    step.description = "Найдена клетка, которая должна войти в базис на следующем этапе.";
    step.calculationText = deltaText;

    step.costMatrix = costs;
    step.supply = supply;
    step.demand = demand;
    step.loadMatrix = loadMatrix;
    step.markMatrix = basisMarks;
    step.selectedRow = minRow;
    step.selectedCol = minCol;

    result.steps.push_back(step);

    result.valid = true;
    result.optimal = false;
    result.enterRow = minRow;
    result.enterCol = minCol;
    result.message = "Проверка оптимальности завершена: план не оптимален.";
    return result;
}
