#ifndef THEORYCONTROLLER_H
#define THEORYCONTROLLER_H

#pragma once

#include <QObject>
#include <QVariantList>
#include <QString>

#include "TransportProblemState.h"
#include "balancesolver.h"
#include "mincostsolver.h"
#include "potentialsolver.h"
#include "cyclesolver.h"
#include "recalculationsolver.h"

struct TheoryUnifiedStep
{
    QString stage;
    QString title;
    QString description;
    QString calculationText;

    QVector<QVector<int>> costMatrix;
    QVector<int> supply;
    QVector<int> demand;

    QVector<QVector<QString>> loadMatrix;
    QVector<QVector<QString>> markMatrix;

    int selectedRow = -1;
    int selectedCol = -1;
};

class TheoryController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)
    Q_PROPERTY(bool balanceNeeded READ balanceNeeded NOTIFY balanceResultChanged)
    Q_PROPERTY(int resultRows READ resultRows NOTIFY balanceResultChanged)
    Q_PROPERTY(int resultCols READ resultCols NOTIFY balanceResultChanged)
    Q_PROPERTY(QVariantList resultCostMatrix READ resultCostMatrix NOTIFY balanceResultChanged)
    Q_PROPERTY(QVariantList resultSupply READ resultSupply NOTIFY balanceResultChanged)
    Q_PROPERTY(QVariantList resultDemand READ resultDemand NOTIFY balanceResultChanged)

    Q_PROPERTY(QVariantList minCostSteps READ minCostSteps NOTIFY minCostStepsChanged)
    Q_PROPERTY(QVariantList minCostFinalLoadMatrix READ minCostFinalLoadMatrix NOTIFY minCostStepsChanged)
    Q_PROPERTY(QVariantList potentialSteps READ potentialSteps NOTIFY potentialStepsChanged)
    Q_PROPERTY(bool potentialOptimal READ potentialOptimal NOTIFY potentialStepsChanged)
    Q_PROPERTY(QVariantList cycleSteps READ cycleSteps NOTIFY cycleStepsChanged)
    Q_PROPERTY(QVariantList recalculationSteps READ recalculationSteps NOTIFY recalculationStepsChanged)

    Q_PROPERTY(QVariantList allSteps READ allSteps NOTIFY allStepsChanged)

public:
    explicit TheoryController(QObject* parent = nullptr);

    QString statusText() const;
    bool balanceNeeded() const;

    int resultRows() const;
    int resultCols() const;

    QVariantList resultCostMatrix() const;
    QVariantList resultSupply() const;
    QVariantList resultDemand() const;

    QVariantList minCostSteps() const;
    QVariantList minCostFinalLoadMatrix() const;
    QVariantList potentialSteps() const;
    QVariantList cycleSteps() const;
    QVariantList recalculationSteps() const;

    QVariantList allSteps() const;

    bool potentialOptimal() const;

    Q_INVOKABLE int currentTotalCost() const;

    Q_INVOKABLE bool runBalanceStage(const QVariantList& costMatrix,
                                     const QVariantList& supply,
                                     const QVariantList& demand);
    Q_INVOKABLE bool runMinCostStage();
    Q_INVOKABLE bool runPotentialStage();
    Q_INVOKABLE bool runCycleStage();
    Q_INVOKABLE bool runRecalculationStage();

    Q_INVOKABLE bool solveAll(const QVariantList& costMatrix,
                              const QVariantList& supply,
                              const QVariantList& demand);

    Q_INVOKABLE void clear();

signals:
    void statusTextChanged();
    void balanceResultChanged();
    void minCostStepsChanged();
    void potentialStepsChanged();
    void cycleStepsChanged();
    void recalculationStepsChanged();
    void allStepsChanged();

private:
    TransportProblemState m_state;
    BalanceSolver m_balanceSolver;
    BalanceResult m_balanceResult;
    QString m_statusText;

    TransportProblemState m_balancedState;
    MinCostSolver m_minCostSolver;
    MinCostResult m_minCostResult;

    PotentialSolver m_potentialSolver;
    PotentialResult m_potentialResult;

    CycleSolver m_cycleSolver;
    CycleResult m_cycleResult;

    RecalculationSolver m_recalculationSolver;
    RecalculationResult m_recalculationResult;

    QVector<QVector<QString>> m_currentLoadMatrix;

    QVector<TheoryUnifiedStep> m_allSteps;
    QVariantList m_allStepsCache;

    void setStatusText(const QString& text);

    bool parseMatrix(const QVariantList& input, QVector<QVector<int>>& output) const;
    bool parseVector(const QVariantList& input, QVector<int>& output) const;

    QVariantList toVariant2D(const QVector<QVector<int>>& matrix) const;
    QVariantList toVariant1D(const QVector<int>& vec) const;
    QVariantList toVariant2DString(const QVector<QVector<QString>>& matrix) const;
    QVariantMap toVariantUnifiedStep(const TheoryUnifiedStep& step) const;

    QVector<QVector<QString>> makeStringMatrix(int rows, int cols) const;

    void rebuildAllStepsCache();
    void appendUnifiedStep(const TheoryUnifiedStep& step);

    TheoryUnifiedStep buildInputUnifiedStep() const;
    TheoryUnifiedStep buildBalancedUnifiedStep() const;
    TheoryUnifiedStep buildFinalUnifiedStep() const;

    void appendMinCostStepsToAll();
    void appendPotentialStepsToAll(int iteration);
    void appendCycleStepsToAll(int iteration);
    void appendRecalculationStepsToAll(int iteration);
};

#endif // THEORYCONTROLLER_H
