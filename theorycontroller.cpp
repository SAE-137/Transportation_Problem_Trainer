#include "theoryController.h"

#include <QDebug>

TheoryController::TheoryController(QObject* parent)
    : QObject(parent)
{
}

QString TheoryController::statusText() const
{
    return m_statusText;
}

bool TheoryController::balanceNeeded() const
{
    return m_balanceResult.valid && !m_balanceResult.alreadyBalanced;
}

int TheoryController::resultRows() const
{
    return m_balanceResult.costMatrix.size();
}

int TheoryController::resultCols() const
{
    if (m_balanceResult.costMatrix.isEmpty())
        return 0;

    return m_balanceResult.costMatrix[0].size();
}

QVariantList TheoryController::resultCostMatrix() const
{
    return toVariant2D(m_balanceResult.costMatrix);
}

QVariantList TheoryController::resultSupply() const
{
    return toVariant1D(m_balanceResult.supply);
}

QVariantList TheoryController::resultDemand() const
{
    return toVariant1D(m_balanceResult.demand);
}

QVariantList TheoryController::allSteps() const
{
    return m_allStepsCache;
}

void TheoryController::setStatusText(const QString& text)
{
    if (m_statusText == text)
        return;

    m_statusText = text;
    emit statusTextChanged();
}

bool TheoryController::parseMatrix(const QVariantList& input, QVector<QVector<int>>& output) const
{
    output.clear();

    if (input.isEmpty())
        return false;

    int expectedCols = -1;

    for (const QVariant& rowVar : input) {
        const QVariantList rowList = rowVar.toList();
        if (rowList.isEmpty())
            return false;

        if (expectedCols == -1)
            expectedCols = rowList.size();
        else if (rowList.size() != expectedCols)
            return false;

        QVector<int> row;
        row.reserve(rowList.size());

        for (const QVariant& cellVar : rowList) {
            bool ok = false;
            const int value = cellVar.toString().toInt(&ok);
            if (!ok)
                return false;

            row.push_back(value);
        }

        output.push_back(row);
    }

    return true;
}

bool TheoryController::parseVector(const QVariantList& input, QVector<int>& output) const
{
    output.clear();

    if (input.isEmpty())
        return false;

    for (const QVariant& valueVar : input) {
        bool ok = false;
        const int value = valueVar.toString().toInt(&ok);
        if (!ok)
            return false;

        output.push_back(value);
    }

    return true;
}

QVariantList TheoryController::toVariant2D(const QVector<QVector<int>>& matrix) const
{
    QVariantList result;

    for (const auto& row : matrix) {
        QVariantList rowList;
        for (int value : row)
            rowList.push_back(value);
        result.push_back(rowList);
    }

    return result;
}

QVariantList TheoryController::toVariant1D(const QVector<int>& vec) const
{
    QVariantList result;

    for (int value : vec)
        result.push_back(value);

    return result;
}

QVariantList TheoryController::toVariant2DString(const QVector<QVector<QString>>& matrix) const
{
    QVariantList result;

    for (const auto& row : matrix) {
        QVariantList rowList;
        for (const QString& value : row)
            rowList.push_back(value);
        result.push_back(rowList);
    }

    return result;
}

QVariantMap TheoryController::toVariantUnifiedStep(const TheoryUnifiedStep& step) const
{
    QVariantMap item;
    item["stage"] = step.stage;
    item["title"] = step.title;
    item["description"] = step.description;
    item["calculationText"] = step.calculationText;
    item["rows"] = step.costMatrix.size();
    item["cols"] = step.costMatrix.isEmpty() ? 0 : step.costMatrix[0].size();
    item["costMatrix"] = toVariant2D(step.costMatrix);
    item["supply"] = toVariant1D(step.supply);
    item["demand"] = toVariant1D(step.demand);
    item["loadMatrix"] = toVariant2DString(step.loadMatrix);
    item["markMatrix"] = toVariant2DString(step.markMatrix);
    item["selectedRow"] = step.selectedRow;
    item["selectedCol"] = step.selectedCol;
    return item;
}

QVector<QVector<QString>> TheoryController::makeStringMatrix(int rows, int cols) const
{
    return QVector<QVector<QString>>(rows, QVector<QString>(cols, ""));
}

void TheoryController::rebuildAllStepsCache()
{
    m_allStepsCache.clear();
    for (const TheoryUnifiedStep& step : m_allSteps)
        m_allStepsCache.push_back(toVariantUnifiedStep(step));
}

void TheoryController::appendUnifiedStep(const TheoryUnifiedStep& step)
{
    m_allSteps.push_back(step);
}

TheoryUnifiedStep TheoryController::buildInputUnifiedStep() const
{
    TheoryUnifiedStep step;
    step.stage = "Ввод";
    step.title = "Исходная задача";
    step.description = "Исходная транспортная задача до этапа балансировки.";
    step.costMatrix = m_state.costMatrix();
    step.supply = m_state.supply();
    step.demand = m_state.demand();
    step.loadMatrix = makeStringMatrix(m_state.rows(), m_state.cols());
    step.markMatrix = makeStringMatrix(m_state.rows(), m_state.cols());
    return step;
}

TheoryUnifiedStep TheoryController::buildBalancedUnifiedStep() const
{
    TheoryUnifiedStep step;
    step.stage = "Балансировка";
    step.title = m_balanceResult.alreadyBalanced
                     ? "Балансировка не требуется"
                     : "Задача после балансировки";
    step.description = m_balanceResult.message;
    step.costMatrix = m_balanceResult.costMatrix;
    step.supply = m_balanceResult.supply;
    step.demand = m_balanceResult.demand;
    step.loadMatrix = makeStringMatrix(step.costMatrix.size(),
                                       step.costMatrix.isEmpty() ? 0 : step.costMatrix[0].size());
    step.markMatrix = makeStringMatrix(step.costMatrix.size(),
                                       step.costMatrix.isEmpty() ? 0 : step.costMatrix[0].size());
    return step;
}

TheoryUnifiedStep TheoryController::buildFinalUnifiedStep() const
{
    TheoryUnifiedStep step;
    step.stage = "Финал";
    step.title = "Оптимальное решение найдено";
    step.description = "После очередной проверки оптимальности все оценки стали неотрицательными.";

    step.costMatrix = m_balancedState.costMatrix();
    step.supply = m_balancedState.supply();
    step.demand = m_balancedState.demand();
    step.loadMatrix = m_currentLoadMatrix;
    step.markMatrix = makeStringMatrix(m_balancedState.rows(), m_balancedState.cols());

    QString calcText = "Итоговая стоимость плана:\n";
    for (int r = 0; r < m_balancedState.rows(); ++r) {
        for (int c = 0; c < m_balancedState.cols(); ++c) {
            const QString x = m_currentLoadMatrix[r][c].trimmed();
            if (x.isEmpty())
                continue;

            bool ok = false;
            const int load = x.toInt(&ok);
            if (!ok)
                continue;

            const int cost = m_balancedState.costMatrix()[r][c];
            calcText += QString("c%1%2 * x%1%2 = %3 * %4 = %5\n")
                            .arg(r + 1)
                            .arg(c + 1)
                            .arg(cost)
                            .arg(load)
                            .arg(cost * load);
        }
    }
    calcText += QString("\nZ = %1").arg(currentTotalCost());

    step.calculationText = calcText;
    return step;
}

void TheoryController::appendMinCostStepsToAll()
{
    for (const MinCostStep& raw : m_minCostResult.steps) {
        TheoryUnifiedStep step;
        step.stage = "Минимальный тариф";
        step.title = raw.title;
        step.description = raw.description;
        step.costMatrix = raw.costMatrix;
        step.supply = raw.supply;
        step.demand = raw.demand;
        step.loadMatrix = raw.loadMatrix;
        step.markMatrix = raw.markMatrix;
        step.selectedRow = raw.selectedRow;
        step.selectedCol = raw.selectedCol;
        appendUnifiedStep(step);
    }
}

void TheoryController::appendPotentialStepsToAll(int iteration)
{
    for (const PotentialStep& raw : m_potentialResult.steps) {
        TheoryUnifiedStep step;
        step.stage = "Потенциалы";
        step.title = QString("Итерация %1. ").arg(iteration) + raw.title;
        step.description = raw.description;
        step.calculationText = raw.calculationText;
        step.costMatrix = raw.costMatrix;
        step.supply = raw.supply;
        step.demand = raw.demand;
        step.loadMatrix = raw.loadMatrix;
        step.markMatrix = raw.markMatrix;
        step.selectedRow = raw.selectedRow;
        step.selectedCol = raw.selectedCol;
        appendUnifiedStep(step);
    }
}

void TheoryController::appendCycleStepsToAll(int iteration)
{
    for (const CycleStep& raw : m_cycleResult.steps) {
        TheoryUnifiedStep step;
        step.stage = "Цикл пересчёта";
        step.title = QString("Итерация %1. ").arg(iteration) + raw.title;
        step.description = raw.description;
        step.calculationText = raw.calculationText;
        step.costMatrix = raw.costMatrix;
        step.supply = raw.supply;
        step.demand = raw.demand;
        step.loadMatrix = raw.loadMatrix;
        step.markMatrix = raw.markMatrix;
        step.selectedRow = raw.selectedRow;
        step.selectedCol = raw.selectedCol;
        appendUnifiedStep(step);
    }
}

void TheoryController::appendRecalculationStepsToAll(int iteration)
{
    for (const RecalculationStep& raw : m_recalculationResult.steps) {
        TheoryUnifiedStep step;
        step.stage = "Пересчёт плана";
        step.title = QString("Итерация %1. ").arg(iteration) + raw.title;
        step.description = raw.description;
        step.calculationText = raw.calculationText;
        step.costMatrix = raw.costMatrix;
        step.supply = raw.supply;
        step.demand = raw.demand;
        step.loadMatrix = raw.loadMatrix;
        step.markMatrix = raw.markMatrix;
        step.selectedRow = raw.selectedRow;
        step.selectedCol = raw.selectedCol;
        appendUnifiedStep(step);
    }
}

bool TheoryController::runBalanceStage(const QVariantList& costMatrix,
                                       const QVariantList& supply,
                                       const QVariantList& demand)
{
    QVector<QVector<int>> costs;
    QVector<int> supplyVec;
    QVector<int> demandVec;

    if (!parseMatrix(costMatrix, costs)) {
        setStatusText("Ошибка: не удалось прочитать матрицу тарифов.");
        return false;
    }

    if (!parseVector(supply, supplyVec)) {
        setStatusText("Ошибка: не удалось прочитать запасы.");
        return false;
    }

    if (!parseVector(demand, demandVec)) {
        setStatusText("Ошибка: не удалось прочитать потребности.");
        return false;
    }

    QString errorText;
    if (!m_state.setData(costs, supplyVec, demandVec, errorText)) {
        setStatusText("Ошибка: " + errorText);
        return false;
    }

    m_balanceResult = m_balanceSolver.solve(m_state);

    if (!m_balanceResult.valid) {
        setStatusText("Ошибка: не удалось выполнить балансировку.");
        return false;
    }

    QString balancedError;
    if (!m_balancedState.setData(m_balanceResult.costMatrix,
                                 m_balanceResult.supply,
                                 m_balanceResult.demand,
                                 balancedError)) {
        setStatusText("Ошибка: не удалось сохранить сбалансированную задачу.");
        return false;
    }

    setStatusText(m_balanceResult.message);
    emit balanceResultChanged();
    return true;
}

QVariantList TheoryController::minCostSteps() const
{
    QVariantList result;

    for (const MinCostStep& step : m_minCostResult.steps) {
        QVariantMap item;
        item["title"] = step.title;
        item["description"] = step.description;
        item["rows"] = step.costMatrix.size();
        item["cols"] = step.costMatrix.isEmpty() ? 0 : step.costMatrix[0].size();
        item["costMatrix"] = toVariant2D(step.costMatrix);
        item["supply"] = toVariant1D(step.supply);
        item["demand"] = toVariant1D(step.demand);
        item["loadMatrix"] = toVariant2DString(step.loadMatrix);
        item["markMatrix"] = toVariant2DString(step.markMatrix);
        item["selectedRow"] = step.selectedRow;
        item["selectedCol"] = step.selectedCol;
        result.push_back(item);
    }

    return result;
}

QVariantList TheoryController::minCostFinalLoadMatrix() const
{
    return toVariant2DString(m_minCostResult.finalLoadMatrix);
}

bool TheoryController::runMinCostStage()
{
    if (m_balancedState.rows() <= 0 || m_balancedState.cols() <= 0) {
        setStatusText("Сначала нужно выполнить этап балансировки.");
        return false;
    }

    m_minCostResult = m_minCostSolver.solve(m_balancedState);

    if (!m_minCostResult.valid) {
        setStatusText("Ошибка: не удалось построить опорный план методом минимального тарифа.");
        emit minCostStepsChanged();
        return false;
    }

    m_currentLoadMatrix = m_minCostResult.finalLoadMatrix;

    setStatusText(m_minCostResult.message);
    emit minCostStepsChanged();
    return true;
}

QVariantList TheoryController::potentialSteps() const
{
    QVariantList result;

    for (const PotentialStep& step : m_potentialResult.steps) {
        QVariantMap item;
        item["title"] = step.title;
        item["description"] = step.description;
        item["calculationText"] = step.calculationText;
        item["rows"] = step.costMatrix.size();
        item["cols"] = step.costMatrix.isEmpty() ? 0 : step.costMatrix[0].size();
        item["costMatrix"] = toVariant2D(step.costMatrix);
        item["supply"] = toVariant1D(step.supply);
        item["demand"] = toVariant1D(step.demand);
        item["loadMatrix"] = toVariant2DString(step.loadMatrix);
        item["markMatrix"] = toVariant2DString(step.markMatrix);
        item["selectedRow"] = step.selectedRow;
        item["selectedCol"] = step.selectedCol;
        result.push_back(item);
    }

    return result;
}

bool TheoryController::runPotentialStage()
{
    m_cycleResult = CycleResult();
    emit cycleStepsChanged();

    if (m_balancedState.rows() <= 0 || m_balancedState.cols() <= 0) {
        setStatusText("Сначала нужно выполнить балансировку.");
        return false;
    }

    if (m_currentLoadMatrix.isEmpty()) {
        setStatusText("Сначала нужно построить опорный план методом минимального тарифа.");
        return false;
    }

    m_cycleResult = CycleResult();
    emit cycleStepsChanged();

    m_recalculationResult = RecalculationResult();
    emit recalculationStepsChanged();

    m_potentialResult = m_potentialSolver.solve(m_balancedState, m_currentLoadMatrix);

    if (!m_potentialResult.valid) {
        setStatusText(m_potentialResult.message);
        emit potentialStepsChanged();
        return false;
    }

    setStatusText(m_potentialResult.message);
    emit potentialStepsChanged();
    return true;
}

bool TheoryController::potentialOptimal() const
{
    return m_potentialResult.valid && m_potentialResult.optimal;
}

QVariantList TheoryController::cycleSteps() const
{
    QVariantList result;

    for (const CycleStep& step : m_cycleResult.steps) {
        QVariantMap item;
        item["title"] = step.title;
        item["description"] = step.description;
        item["calculationText"] = step.calculationText;
        item["rows"] = step.costMatrix.size();
        item["cols"] = step.costMatrix.isEmpty() ? 0 : step.costMatrix[0].size();
        item["costMatrix"] = toVariant2D(step.costMatrix);
        item["supply"] = toVariant1D(step.supply);
        item["demand"] = toVariant1D(step.demand);
        item["loadMatrix"] = toVariant2DString(step.loadMatrix);
        item["markMatrix"] = toVariant2DString(step.markMatrix);
        item["selectedRow"] = step.selectedRow;
        item["selectedCol"] = step.selectedCol;
        result.push_back(item);
    }

    return result;
}

int TheoryController::currentTotalCost() const
{
    if (m_balancedState.rows() <= 0 || m_balancedState.cols() <= 0)
        return 0;

    if (m_currentLoadMatrix.isEmpty())
        return 0;

    int total = 0;
    const auto& costs = m_balancedState.costMatrix();

    for (int r = 0; r < m_balancedState.rows(); ++r) {
        for (int c = 0; c < m_balancedState.cols(); ++c) {
            const QString x = m_currentLoadMatrix[r][c].trimmed();
            if (x.isEmpty())
                continue;

            bool ok = false;
            const int value = x.toInt(&ok);
            if (ok)
                total += value * costs[r][c];
        }
    }

    return total;
}

bool TheoryController::runCycleStage()
{
    if (m_balancedState.rows() <= 0 || m_balancedState.cols() <= 0) {
        setStatusText("Сначала нужно выполнить балансировку.");
        return false;
    }

    if (m_currentLoadMatrix.isEmpty()) {
        setStatusText("Сначала нужно построить опорный план методом минимального тарифа.");
        return false;
    }

    m_cycleResult = CycleResult();
    emit cycleStepsChanged();

    m_recalculationResult = RecalculationResult();
    emit recalculationStepsChanged();

    m_potentialResult = m_potentialSolver.solve(m_balancedState, m_currentLoadMatrix);

    if (!m_potentialResult.valid) {
        setStatusText("Сначала нужно выполнить этап проверки оптимальности.");
        return false;
    }

    if (m_potentialResult.optimal) {
        setStatusText("Цикл пересчёта не нужен: план уже оптимален.");
        emit cycleStepsChanged();
        return false;
    }

    m_cycleResult = m_cycleSolver.solve(
        m_balancedState,
        m_currentLoadMatrix,
        m_potentialResult.enterRow,
        m_potentialResult.enterCol
        );

    if (!m_cycleResult.valid) {
        setStatusText(m_cycleResult.message);
        emit cycleStepsChanged();
        return false;
    }

    setStatusText(m_cycleResult.message);
    emit cycleStepsChanged();
    return true;
}

bool TheoryController::runRecalculationStage()
{
    if (m_balancedState.rows() <= 0 || m_balancedState.cols() <= 0) {
        setStatusText("Сначала нужно выполнить балансировку.");
        return false;
    }

    if (m_currentLoadMatrix.isEmpty()) {
        setStatusText("Нет текущего плана перевозок для пересчёта.");
        return false;
    }

    if (!m_cycleResult.valid || m_cycleResult.cyclePath.isEmpty()) {
        setStatusText("Сначала нужно построить цикл пересчёта.");
        return false;
    }

    m_recalculationResult = m_recalculationSolver.solve(
        m_balancedState,
        m_currentLoadMatrix,
        m_cycleResult.cyclePath
        );

    if (!m_recalculationResult.valid) {
        setStatusText(m_recalculationResult.message);
        emit recalculationStepsChanged();
        return false;
    }

    m_currentLoadMatrix = m_recalculationResult.newLoadMatrix;

    setStatusText(m_recalculationResult.message);
    emit recalculationStepsChanged();
    return true;
}

QVariantList TheoryController::recalculationSteps() const
{
    QVariantList result;

    for (const RecalculationStep& step : m_recalculationResult.steps) {
        QVariantMap item;
        item["title"] = step.title;
        item["description"] = step.description;
        item["calculationText"] = step.calculationText;
        item["rows"] = step.costMatrix.size();
        item["cols"] = step.costMatrix.isEmpty() ? 0 : step.costMatrix[0].size();
        item["costMatrix"] = toVariant2D(step.costMatrix);
        item["supply"] = toVariant1D(step.supply);
        item["demand"] = toVariant1D(step.demand);
        item["loadMatrix"] = toVariant2DString(step.loadMatrix);
        item["markMatrix"] = toVariant2DString(step.markMatrix);
        item["selectedRow"] = step.selectedRow;
        item["selectedCol"] = step.selectedCol;
        result.push_back(item);
    }

    return result;
}

bool TheoryController::solveAll(const QVariantList& costMatrix,
                                const QVariantList& supply,
                                const QVariantList& demand)
{
    clear();

    QVector<QVector<int>> costs;
    QVector<int> supplyVec;
    QVector<int> demandVec;

    if (!parseMatrix(costMatrix, costs)) {
        setStatusText("Ошибка: не удалось прочитать матрицу тарифов.");
        return false;
    }

    if (!parseVector(supply, supplyVec)) {
        setStatusText("Ошибка: не удалось прочитать запасы.");
        return false;
    }

    if (!parseVector(demand, demandVec)) {
        setStatusText("Ошибка: не удалось прочитать потребности.");
        return false;
    }

    QString errorText;
    if (!m_state.setData(costs, supplyVec, demandVec, errorText)) {
        setStatusText("Ошибка: " + errorText);
        return false;
    }

    m_balanceResult = m_balanceSolver.solve(m_state);
    if (!m_balanceResult.valid) {
        setStatusText("Ошибка: не удалось выполнить балансировку.");
        return false;
    }

    QString balancedError;
    if (!m_balancedState.setData(m_balanceResult.costMatrix,
                                 m_balanceResult.supply,
                                 m_balanceResult.demand,
                                 balancedError)) {
        setStatusText("Ошибка: не удалось сохранить сбалансированную задачу.");
        return false;
    }

    emit balanceResultChanged();

    m_allSteps.clear();
    m_allStepsCache.clear();

    appendUnifiedStep(buildInputUnifiedStep());
    appendUnifiedStep(buildBalancedUnifiedStep());

    m_minCostResult = m_minCostSolver.solve(m_balancedState);
    emit minCostStepsChanged();

    if (!m_minCostResult.valid) {
        setStatusText("Ошибка: не удалось построить опорный план методом минимального тарифа.");
        rebuildAllStepsCache();
        emit allStepsChanged();
        return false;
    }

    m_currentLoadMatrix = m_minCostResult.finalLoadMatrix;
    appendMinCostStepsToAll();

    int iteration = 1;

    while (true) {
        m_cycleResult = CycleResult();
        emit cycleStepsChanged();

        m_recalculationResult = RecalculationResult();
        emit recalculationStepsChanged();

        m_potentialResult = m_potentialSolver.solve(m_balancedState, m_currentLoadMatrix);
        emit potentialStepsChanged();

        if (!m_potentialResult.valid) {
            setStatusText(m_potentialResult.message);
            rebuildAllStepsCache();
            emit allStepsChanged();
            return false;
        }

        appendPotentialStepsToAll(iteration);

        if (m_potentialResult.optimal)
            break;

        m_cycleResult = m_cycleSolver.solve(
            m_balancedState,
            m_currentLoadMatrix,
            m_potentialResult.enterRow,
            m_potentialResult.enterCol
            );
        emit cycleStepsChanged();

        if (!m_cycleResult.valid) {
            setStatusText(m_cycleResult.message);
            rebuildAllStepsCache();
            emit allStepsChanged();
            return false;
        }

        appendCycleStepsToAll(iteration);

        m_recalculationResult = m_recalculationSolver.solve(
            m_balancedState,
            m_currentLoadMatrix,
            m_cycleResult.cyclePath
            );
        emit recalculationStepsChanged();

        if (!m_recalculationResult.valid) {
            setStatusText(m_recalculationResult.message);
            rebuildAllStepsCache();
            emit allStepsChanged();
            return false;
        }

        appendRecalculationStepsToAll(iteration);
        m_currentLoadMatrix = m_recalculationResult.newLoadMatrix;

        ++iteration;
    }

    appendUnifiedStep(buildFinalUnifiedStep());

    rebuildAllStepsCache();
    emit allStepsChanged();

    setStatusText(QString("Решение построено полностью. Количество шагов: %1.")
                      .arg(m_allSteps.size()));
    return true;
}

void TheoryController::clear()
{
    m_state.clear();
    m_balanceResult = BalanceResult();
    setStatusText("");
    emit balanceResultChanged();

    m_balancedState.clear();

    m_minCostResult = MinCostResult();
    emit minCostStepsChanged();

    m_potentialResult = PotentialResult();
    emit potentialStepsChanged();

    m_cycleResult = CycleResult();
    emit cycleStepsChanged();

    m_recalculationResult = RecalculationResult();
    emit recalculationStepsChanged();

    m_currentLoadMatrix.clear();

    m_allSteps.clear();
    m_allStepsCache.clear();
    emit allStepsChanged();
}
