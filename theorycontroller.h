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
    Q_PROPERTY(bool potentialOptimal READ potentialOptimal NOTIFY potentialStepsChanged)

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

    QVariantList recalculationSteps() const;

    //bool potentialOptimal() const;

    Q_INVOKABLE int currentTotalCost() const;

    Q_INVOKABLE bool runRecalculationStage();

    Q_INVOKABLE bool runPotentialStage();

    Q_INVOKABLE bool runMinCostStage();

    Q_INVOKABLE bool runBalanceStage(const QVariantList& costMatrix,
                                     const QVariantList& supply,
                                     const QVariantList& demand);

    Q_INVOKABLE void clear();

    bool potentialOptimal() const;
    QVariantList cycleSteps() const;

    Q_INVOKABLE bool runCycleStage();



signals:
    void statusTextChanged();
    void balanceResultChanged();
    void minCostStepsChanged();
    void potentialStepsChanged();
    void cycleStepsChanged();
    void recalculationStepsChanged();

private:
    TransportProblemState m_state;
    BalanceSolver m_balanceSolver;
    BalanceResult m_balanceResult;
    QString m_statusText;

    void setStatusText(const QString& text);

    bool parseMatrix(const QVariantList& input, QVector<QVector<int>>& output) const;
    bool parseVector(const QVariantList& input, QVector<int>& output) const;

    QVariantList toVariant2D(const QVector<QVector<int>>& matrix) const;
    QVariantList toVariant1D(const QVector<int>& vec) const;

    TransportProblemState m_balancedState;
    MinCostSolver m_minCostSolver;
    MinCostResult m_minCostResult;

    QVariantList toVariant2DString(const QVector<QVector<QString>>& matrix) const;

    PotentialSolver m_potentialSolver;
    PotentialResult m_potentialResult;

    CycleSolver m_cycleSolver;
    CycleResult m_cycleResult;

    RecalculationSolver m_recalculationSolver;
    RecalculationResult m_recalculationResult;

    QVector<QVector<QString>> m_currentLoadMatrix;
};

#endif // THEORYCONTROLLER_H
